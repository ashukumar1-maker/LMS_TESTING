"""Authentication override fixture for backend tests."""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest

from src.auth.verify_user import VerifyUserResponse, verify_user
from src.server import app

if TYPE_CHECKING:
    from collections.abc import Generator


@pytest.fixture(autouse=True)
def override_auth() -> Generator[None]:
    """Override the FastAPI verify_user dependency to return a fake user ID.

    This allows tests to bypass authentication without needing real tokens.
    """

    def _fake_verify_user() -> VerifyUserResponse:
        return VerifyUserResponse(uid="test-user-123", email="test@ciridae.com")

    app.dependency_overrides[verify_user] = _fake_verify_user
    yield
    _ = app.dependency_overrides.pop(verify_user, None)
