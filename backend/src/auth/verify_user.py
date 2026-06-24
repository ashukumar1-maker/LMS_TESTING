"""Authentication helpers for verifying Ciridae bearer tokens."""

from __future__ import annotations

import logging
from typing import Annotated

import httpx
from cachetools import TTLCache
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ValidationError

from src.config import settings

# Configure logger for this module
logger = logging.getLogger(__name__)

# Reusable bearer token scheme
reusable_bearer = HTTPBearer(auto_error=False)

# Cache configuration for auth token verification.
TOKEN_CACHE_MAX_ENTRIES = 1000
TOKEN_CACHE_TTL_SECONDS = 300

# Token cache: bearer token -> (user_id, email)
_token_cache = TTLCache[str, tuple[str, str]](
    maxsize=TOKEN_CACHE_MAX_ENTRIES,
    ttl=TOKEN_CACHE_TTL_SECONDS,
)


class VerifyUserResponse(BaseModel):
    """Verified user identity returned by the auth dependency."""

    uid: str
    email: str


class AuthServiceAccessResponse(BaseModel):
    """Response payload returned by the Ciridae auth service access endpoint."""

    has_access: bool = False
    user_id: str | None = None
    email: str | None = None


def is_ciridae(email: str) -> bool:
    """Check if the user is a Ciridae employee.

    Args:
        email: The user's email address.

    Returns:
        True if the email ends with @ciridae.com, False otherwise.
    """
    return email.endswith("@ciridae.com")


def clear_token_cache() -> None:
    """Clear cached token verification responses."""
    _token_cache.clear()


async def verify_user(
    request: Request,
    token: Annotated[HTTPAuthorizationCredentials | None, Depends(reusable_bearer)],
) -> VerifyUserResponse:
    """Verify the token by making a request to the auth service.

    Returns the User ID and email address.
    Will also add the User ID and email address to the request object.
    Results are cached in-memory for a short period to reduce auth-service calls.

    Failure responses:
        `401 Unauthorized`: The bearer token is missing, the auth service denies access,
        or the auth response is missing the expected user data.
        `500 Internal Server Error`: The auth service returns an HTTP error response,
        returns invalid JSON, or an unexpected verification error occurs.
        `503 Service Unavailable`: The auth service cannot be reached.

    Args:
        token: The bearer token credentials provided by FastAPI.
        request: The request object.

    Returns:
        VerifyUserResponse: The User ID and email address of the user.

    Raises:
        HTTPException: If token verification fails or the auth service is unavailable.
    """
    if not token or not token.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Bearer token missing",
            headers={"WWW-Authenticate": "Bearer"},
        )

    cached_user = _token_cache.get(token.credentials)
    if cached_user:
        cached_user_id, cached_email = cached_user
        request.state.user_id = cached_user_id
        request.state.email = cached_email
        return VerifyUserResponse(uid=cached_user_id, email=cached_email)

    headers = {"Authorization": f"Bearer {settings.AUTH_SERVICE_API_KEY}"}
    params = {"firebase_token": token.credentials}
    request_url = f"{settings.AUTH_SERVICE_API_URL}/access"

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(request_url, headers=headers, params=params)
            response = response.raise_for_status()

            response_body = AuthServiceAccessResponse.model_validate_json(response.text)
            user_id, email = _extract_verified_user(response_body)

            _token_cache[token.credentials] = (user_id, email)
            request.state.user_id = user_id
            request.state.email = email

            return VerifyUserResponse(uid=user_id, email=email)

        except HTTPException:
            raise
        except httpx.HTTPStatusError as e:
            logger.exception(
                "Error from auth service: %s, Response status code: %s",
                e.response.text,
                e.response.status_code,
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Authentication error",
            ) from e
        except httpx.RequestError as e:
            logger.exception("Auth service connection error")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service temporarily unavailable",
            ) from e
        except ValidationError as e:
            logger.exception("Invalid response from auth service")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Authentication error",
            ) from e
        except Exception as e:
            logger.exception("Unexpected error during token verification")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Authentication error",
            ) from e


def _extract_verified_user(
    response_body: AuthServiceAccessResponse,
) -> tuple[str, str]:
    """Extract and validate user identity data from an auth-service response.

    Args:
        response_body: The parsed auth-service response body.

    Returns:
        The verified user ID and email address.

    Raises:
        HTTPException: If the auth service denies access or omits user data.
    """
    if not response_body.has_access:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access explicitly denied by auth service logic for this endpoint.",
            headers={"WWW-Authenticate": "Bearer error='invalid_token'"},
        )

    if not response_body.user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User ID not found in auth service response.",
            headers={"WWW-Authenticate": "Bearer error='invalid_token'"},
        )

    if not response_body.email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email not found in auth service response.",
            headers={"WWW-Authenticate": "Bearer error='invalid_token'"},
        )

    return response_body.user_id, response_body.email
