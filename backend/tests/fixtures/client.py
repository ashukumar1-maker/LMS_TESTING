"""HTTP client fixture for backend route tests."""

from collections.abc import AsyncGenerator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from src.server import app


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient]:
    """Provides an async HTTP client for making API requests during tests.

    Uses ASGI transport for fast in-memory requests without network overhead.

    Yields:
        An async HTTP client configured against the FastAPI app.
    """
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
