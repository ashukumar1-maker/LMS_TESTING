"""Unit tests for Ciridae auth token verification."""

from __future__ import annotations

import json
from collections.abc import Callable
from typing import TYPE_CHECKING, Protocol, Self

import httpx
import pytest
from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from starlette.requests import Request
from starlette.types import Scope

import src.auth.verify_user as verify_user_module
from src.config import settings

AUTH_SERVICE_API_KEY = "test-api-key"
AUTH_SERVICE_API_URL = "https://auth.test"
EXPECTED_REQUEST_COUNT_FOR_UNIQUE_TOKENS = 2

if TYPE_CHECKING:
    from types import TracebackType


class MockAuthResponse(Protocol):
    """Protocol for mocked auth service responses."""

    text: str

    def raise_for_status(self) -> Self:
        """Raise if the mocked auth service response is unsuccessful."""
        ...


type MockGetHandler = Callable[
    [str, dict[str, str], dict[str, str]],
    MockAuthResponse,
]


class MockAsyncClient:
    """Async context manager test double for `httpx.AsyncClient`."""

    _get_handler: MockGetHandler

    def __init__(self, get_handler: MockGetHandler) -> None:
        """Create a typed async client test double."""
        self._get_handler = get_handler

    async def __aenter__(self) -> MockAsyncClient:
        """Enter the async context manager.

        Returns:
            The mock async client instance.
        """
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        """Exit the async context manager."""

    async def get(
        self,
        url: str,
        headers: dict[str, str],
        params: dict[str, str],
    ) -> MockAuthResponse:
        """Return a mocked auth service response."""
        return self._get_handler(url, headers, params)


def _build_request() -> tuple[Request, dict[str, object]]:
    """Build a minimal Starlette request object for dependency testing.

    Returns:
        A request object with its backing state dictionary.
    """
    state: dict[str, object] = {}
    headers: list[tuple[bytes, bytes]] = []
    scope: Scope = {
        "type": "http",
        "method": "GET",
        "path": "/",
        "headers": headers,
        "state": state,
    }
    return Request(scope), state


@pytest.fixture(autouse=True)
def clear_token_cache() -> None:
    """Ensure token cache state does not leak between tests."""
    verify_user_module.clear_token_cache()


@pytest.fixture(name="migrate_test_db", autouse=True)
def skip_database_migration_fixture() -> None:
    """Keep mock-only auth unit tests independent from database setup."""


@pytest.fixture(name="override_async_session_local", autouse=True)
def skip_async_session_local_override_fixture() -> None:
    """Keep mock-only auth unit tests independent from database session overrides."""


@pytest.fixture(name="override_get_async_db", autouse=True)
def skip_get_async_db_override_fixture() -> None:
    """Keep mock-only auth unit tests independent from database dependency overrides."""


@pytest.mark.asyncio
async def test_verify_user_uses_cached_result_after_first_success(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Verify repeated calls with the same token only hit auth service once."""

    class MockResponse:
        text: str

        def __init__(self) -> None:
            self.text = json.dumps(
                {
                    "has_access": True,
                    "user_id": "user-123",
                    "email": "user@example.com",
                }
            )

        def raise_for_status(self) -> Self:
            _ = self.text
            return self

    requests_made: list[dict[str, object]] = []

    def mock_get(
        url: str, headers: dict[str, str], params: dict[str, str]
    ) -> MockResponse:
        """Mock auth-service HTTP GET call for token verification.

        Args:
            url: Auth service endpoint URL.
            headers: Request headers sent to auth service.
            params: Query parameters sent to auth service.

        Returns:
            A mock auth-service response object.
        """
        requests_made.append({"url": url, "headers": headers, "params": params})
        return MockResponse()

    mock_client = MockAsyncClient(mock_get)

    def build_mock_client() -> MockAsyncClient:
        """Build the mocked auth-service HTTP client.

        Returns:
            The mock async client for this test.
        """
        return mock_client

    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_URL",
        AUTH_SERVICE_API_URL,
        raising=False,
    )
    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_KEY",
        AUTH_SERVICE_API_KEY,
        raising=False,
    )
    monkeypatch.setattr(httpx, "AsyncClient", build_mock_client)

    token = HTTPAuthorizationCredentials(scheme="Bearer", credentials="firebase-token")

    first_request, first_state = _build_request()
    first_response = await verify_user_module.verify_user(
        request=first_request,
        token=token,
    )

    second_request, second_state = _build_request()
    second_response = await verify_user_module.verify_user(
        request=second_request,
        token=token,
    )

    assert len(requests_made) == 1
    assert requests_made[0]["url"] == f"{AUTH_SERVICE_API_URL}/access"
    assert requests_made[0]["headers"] == {
        "Authorization": f"Bearer {AUTH_SERVICE_API_KEY}"
    }
    assert requests_made[0]["params"] == {"firebase_token": "firebase-token"}

    assert first_response.uid == "user-123"
    assert first_response.email == "user@example.com"
    assert second_response.uid == "user-123"
    assert second_response.email == "user@example.com"
    assert first_state["user_id"] == "user-123"
    assert first_state["email"] == "user@example.com"
    assert second_state["user_id"] == "user-123"
    assert second_state["email"] == "user@example.com"


@pytest.mark.asyncio
async def test_verify_user_cache_is_keyed_by_token(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Verify different tokens produce separate cache entries."""

    class MockResponse:
        firebase_token: str
        text: str

        def __init__(self, firebase_token: str) -> None:
            self.firebase_token = firebase_token
            self.text = json.dumps(
                {
                    "has_access": True,
                    "user_id": f"user-{self.firebase_token}",
                    "email": f"{self.firebase_token}@example.com",
                }
            )

        def raise_for_status(self) -> Self:
            _ = self.text
            return self

    requests_made: list[dict[str, object]] = []

    def mock_get(
        url: str, headers: dict[str, str], params: dict[str, str]
    ) -> MockResponse:
        """Mock auth-service HTTP GET call that varies by token.

        Args:
            url: Auth service endpoint URL.
            headers: Request headers sent to auth service.
            params: Query parameters sent to auth service.

        Returns:
            A mock auth-service response object for the given token.
        """
        requests_made.append({"url": url, "headers": headers, "params": params})
        return MockResponse(firebase_token=params["firebase_token"])

    mock_client = MockAsyncClient(mock_get)

    def build_mock_client() -> MockAsyncClient:
        """Build the mocked auth-service HTTP client.

        Returns:
            The mock async client for this test.
        """
        return mock_client

    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_URL",
        AUTH_SERVICE_API_URL,
        raising=False,
    )
    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_KEY",
        AUTH_SERVICE_API_KEY,
        raising=False,
    )
    monkeypatch.setattr(httpx, "AsyncClient", build_mock_client)

    token_one = HTTPAuthorizationCredentials(scheme="Bearer", credentials="token-one")
    token_two = HTTPAuthorizationCredentials(scheme="Bearer", credentials="token-two")

    token_one_request, token_one_state = _build_request()
    token_two_request, token_two_state = _build_request()

    token_one_response = await verify_user_module.verify_user(
        request=token_one_request,
        token=token_one,
    )
    token_two_response = await verify_user_module.verify_user(
        request=token_two_request,
        token=token_two,
    )

    assert len(requests_made) == EXPECTED_REQUEST_COUNT_FOR_UNIQUE_TOKENS
    assert token_one_response.uid == "user-token-one"
    assert token_two_response.uid == "user-token-two"
    assert token_one_state["user_id"] == "user-token-one"
    assert token_one_state["email"] == "token-one@example.com"
    assert token_two_state["user_id"] == "user-token-two"
    assert token_two_state["email"] == "token-two@example.com"


@pytest.mark.asyncio
async def test_verify_user_sanitizes_auth_service_http_error(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Verify auth-service HTTP errors do not expose raw response text."""

    class MockResponse:
        text: str = "raw upstream auth failure with implementation details"

        def raise_for_status(self) -> Self:
            request = httpx.Request("GET", f"{AUTH_SERVICE_API_URL}/access")
            response = httpx.Response(
                status_code=500,
                request=request,
                text=self.text,
            )
            raise httpx.HTTPStatusError(
                message="Auth service error",
                request=request,
                response=response,
            )

    def mock_get(
        url: str, headers: dict[str, str], params: dict[str, str]
    ) -> MockResponse:
        """Mock an auth-service HTTP failure.

        Args:
            url: Auth service endpoint URL.
            headers: Request headers sent to auth service.
            params: Query parameters sent to auth service.

        Returns:
            A mock response that raises an HTTP status error.
        """
        del url, headers, params
        return MockResponse()

    mock_client = MockAsyncClient(mock_get)

    def build_mock_client() -> MockAsyncClient:
        """Build the mocked auth-service HTTP client.

        Returns:
            The mock async client for this test.
        """
        return mock_client

    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_URL",
        AUTH_SERVICE_API_URL,
        raising=False,
    )
    monkeypatch.setattr(
        settings,
        "AUTH_SERVICE_API_KEY",
        AUTH_SERVICE_API_KEY,
        raising=False,
    )
    monkeypatch.setattr(httpx, "AsyncClient", build_mock_client)

    token = HTTPAuthorizationCredentials(scheme="Bearer", credentials="firebase-token")
    request, _request_state = _build_request()

    with pytest.raises(HTTPException) as exc_info:
        _ = await verify_user_module.verify_user(request=request, token=token)

    assert exc_info.value.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert exc_info.value.detail == "Authentication error"
