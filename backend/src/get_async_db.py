"""Async SQLAlchemy engine and session dependency helpers."""

from collections.abc import AsyncGenerator
from types import TracebackType
from typing import Protocol

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from src.config import settings

# Lazy-initialized engine and session maker
# Created on first use, not at import time (allows OpenAPI generation without DB)
_async_engine: AsyncEngine | None = None
_async_session_local: async_sessionmaker[AsyncSession] | None = None


# These protocols are type-only. They document the minimal callable/context-manager
# interface that `SessionMakerProxy` needs so the real SQLAlchemy sessionmaker and
# test doubles can be swapped in without loosening everything to `Any`.
class SessionFactory(Protocol):
    """Callable session factory used by `SessionMakerProxy`."""

    def __call__(
        self,
        *args: object,
        **kwargs: object,
    ) -> "SessionContextManager":
        """Create an async session context manager."""
        ...


class SessionContextManager(Protocol):
    """Async context manager that yields an `AsyncSession`."""

    async def __aenter__(self) -> AsyncSession:
        """Enter the async context manager and return a session."""
        ...

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
        /,
    ) -> bool | None:
        """Exit the async context manager."""
        ...


def _get_async_engine() -> AsyncEngine:
    """Get or create the async database engine.

    Returns:
        The async SQLAlchemy engine with connection pooling configured.
    """
    global _async_engine  # noqa: PLW0603
    if _async_engine is None:
        async_database_url = settings.DATABASE_URL.replace(
            "postgresql://", "postgresql+asyncpg://"
        ).replace("sslmode=", "ssl=")
        _async_engine = create_async_engine(
            async_database_url,
            pool_size=settings.DB_POOL_SIZE,
            max_overflow=settings.DB_MAX_OVERFLOW,
            pool_timeout=120,
            pool_pre_ping=True,
        )
    return _async_engine


def _get_session_maker() -> async_sessionmaker[AsyncSession]:
    """Get or create the async session maker.

    Returns:
        The async session maker configured with the engine.
    """
    global _async_session_local  # noqa: PLW0603
    if _async_session_local is None:
        _async_session_local = async_sessionmaker(
            _get_async_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False,
        )
    return _async_session_local


class SessionMakerProxy:
    """A proxy for the async session maker that allows swapping the implementation at runtime.

    This is useful for testing where we need to mock the session maker globally.
    """

    def __init__(self) -> None:
        """Create a proxy with no session maker override."""
        self._override: SessionFactory | None = None

    def __call__(self, *args: object, **kwargs: object) -> SessionContextManager:
        """Create a new session using the current session maker.

        Returns:
            An async context manager that yields a database session.
        """
        maker = self._override if self._override is not None else _get_session_maker()
        return maker(*args, **kwargs)

    def set_backend(self, new_maker: SessionFactory) -> None:
        """Override the underlying session maker (accepts mocks for testing)."""
        self._override = new_maker

    def reset(self) -> None:
        """Reset to the default session maker."""
        self._override = None


# Wrap in our proxy for test mockability
AsyncSessionLocal = SessionMakerProxy()


async def get_async_db() -> AsyncGenerator[AsyncSession]:
    """Dependency to get async database session.

    Yields:
        An async database session that is automatically closed after use.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
