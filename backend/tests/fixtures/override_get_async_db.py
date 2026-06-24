"""FastAPI database dependency override fixture for backend tests."""

from __future__ import annotations

from collections.abc import (
    AsyncGenerator,  # noqa: TC003 - FastAPI may inspect dependency annotations at runtime.
)

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from src.get_async_db import get_async_db
from src.server import app


@pytest_asyncio.fixture(autouse=True)
async def override_get_async_db(
    db_session: AsyncSession,
) -> AsyncGenerator[None]:
    """Override the FastAPI get_async_db dependency to use the test database session.

    This ensures all API routes use the test database during tests.
    """
    _ = await db_session.run_sync(_noop_sync_session)

    async def _get_test_db() -> AsyncGenerator[AsyncSession]:
        await db_session.run_sync(_noop_sync_session)
        yield db_session

    app.dependency_overrides[get_async_db] = _get_test_db
    yield
    _ = app.dependency_overrides.pop(get_async_db, None)


def _noop_sync_session(sync_session: object) -> None:
    """Touch the sync session bridge so the async fixture dependency awaits."""
    del sync_session
