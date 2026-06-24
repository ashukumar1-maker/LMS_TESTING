"""Fixture for redirecting direct async session creation to the test session."""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from src.get_async_db import AsyncSessionLocal

if TYPE_CHECKING:
    from collections.abc import AsyncGenerator
    from types import TracebackType


@pytest_asyncio.fixture(autouse=True)
async def override_async_session_local(
    db_session: AsyncSession,
) -> AsyncGenerator[None]:
    """Mock AsyncSessionLocal to return the test database session.

    This ensures that code which directly instantiates sessions via
    AsyncSessionLocal() (instead of using the get_async_db dependency)
    will use the test database session within the same transaction.
    """
    _ = await db_session.run_sync(_noop_sync_session)

    class MockAsyncSessionLocal:
        """Mock async session maker that returns the test session."""

        def __call__(
            self,
            *args: object,
            **kwargs: object,
        ) -> MockAsyncSessionLocal:
            """Return self to support: async with AsyncSessionLocal() as session."""
            del args, kwargs
            return self

        async def __aenter__(self) -> AsyncSession:
            """Return the test session when entering context manager."""
            print("entering context manager (via proxy)")
            return db_session

        async def __aexit__(
            self,
            exc_type: type[BaseException] | None,
            exc_val: BaseException | None,
            exc_tb: TracebackType | None,
        ) -> bool | None:
            """Exit the context manager without committing or closing.

            Returns:
                `None` to propagate any exception to the caller.
            """
            return None

    # Override the backend in the proxy
    AsyncSessionLocal.set_backend(MockAsyncSessionLocal())

    yield

    # Reset to default (lazy-initialized) session maker
    AsyncSessionLocal.reset()


def _noop_sync_session(sync_session: object) -> None:
    """Touch the sync session bridge so the async fixture awaits."""
    del sync_session
