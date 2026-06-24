"""Database session fixture for backend integration tests."""

from collections.abc import AsyncGenerator

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine


@pytest_asyncio.fixture(scope="function")
async def db_session(postgres_container: str) -> AsyncGenerator[AsyncSession]:
    """Provides a clean async database session for each test function.

    Uses the database URL provided by the postgres_container fixture (local or container).

    Each test runs in a transaction that is rolled back after the test completes,
    ensuring test isolation and a clean database state for each test.

    Yields:
        An async SQLAlchemy session scoped to the current test.
    """
    # Convert sync URL to async
    # Handle both standard postgresql:// and postgresql+psycopg2:// formats
    async_url = postgres_container.replace("postgresql://", "postgresql+asyncpg://")
    async_url = async_url.replace("postgresql+psycopg2://", "postgresql+asyncpg://")

    # Create async engine
    async_engine = create_async_engine(async_url, echo=False)

    # Create a connection and begin a transaction
    async with async_engine.begin() as conn:
        # Create a session bound to this connection
        async_session_maker = async_sessionmaker(
            bind=conn,
            class_=AsyncSession,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False,
        )

        async with async_session_maker() as session:
            try:
                yield session
            finally:
                # Roll back the transaction to clean up test data
                await conn.rollback()

    # Dispose of the engine
    await async_engine.dispose()
