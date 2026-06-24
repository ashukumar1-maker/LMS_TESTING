"""PostgreSQL test database fixture helpers."""

from __future__ import annotations

import os
from typing import TYPE_CHECKING

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError, ProgrammingError
from testcontainers.postgres import PostgresContainer

if TYPE_CHECKING:
    from collections.abc import Generator


class MissingTestDatabaseUrlError(ValueError):
    """Raised when the test database URL cannot be derived from the environment."""

    def __init__(self) -> None:
        """Build the missing test database URL error."""
        super().__init__("DATABASE_URL environment variable is not set")


@pytest.fixture(scope="session")
def postgres_container() -> Generator[str]:
    """Determine and provide the Database URL for the test session.

    Strategy:
    1. Try to use the Local Postgres service (defined by _LOCAL_TEST_DATABASE_URL).
       - If reachable, ensure the specific test DB exists (create if missing).
       - Clear the database to ensure a clean slate.
       - Return the Local URL.
       * The rationale here is that it's much faster to use the local postgres service than to start a new container.

    2. If Local Postgres is not reachable (OperationalError), Fallback to Docker Container.
       - Start a fresh PostgresContainer.
       - Return the Container URL.

    Yields:
        The full SQLAlchemy connection URL to use for tests.
    """
    # 1. Check Local Postgres Availability
    try:
        local_test_database_url = _get_local_test_database_url()
        # To check connectivity, we need to connect to the 'postgres' maintenance DB
        # derived from the local test URL.
        if "/" in local_test_database_url:
            base_url = local_test_database_url.rsplit("/", 1)[0]
            maintenance_url = f"{base_url}/postgres"
        else:
            # Fallback if URL is malformed, though likely won't work
            maintenance_url = local_test_database_url

        # Attempt connection to local server
        engine = create_engine(maintenance_url)
        with engine.connect():
            pass

        # SUCCESS: Local server is running.
        # Now ensure our specific test database (e.g. 'fullstack_test') actually exists.
        _ensure_test_database_exists(local_test_database_url)

        # Ensure the database is clean (drop/recreate public schema)
        _clear_test_database(local_test_database_url)

        yield local_test_database_url

    except (OperationalError, ValueError, IndexError):
        # FAILURE: Local server not running or URL invalid.
        # Fallback: Spin up a Docker container.
        print("Starting test time postgres container")
        yield from provide_postgres_container()


def _get_local_test_database_url() -> str:
    """Get the local test database URL.

    This is done by getting the set DATABASE_URL environment variable and
    replacing the last part of the URL with "fullstack_test".

    Returns:
        The local test database URL derived from `DATABASE_URL`.

    Raises:
        MissingTestDatabaseUrlError: If `DATABASE_URL` is not set.
    """
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise MissingTestDatabaseUrlError
    return database_url.rsplit("/", 1)[0] + "/fullstack_test"


def _ensure_test_database_exists(target_url: str) -> None:
    """Ensures the specific test database exists on the PostgreSQL server.

    This function:
    1. Connects to the default administrative 'postgres' database on the same server.
    2. Checks if the target test database (e.g., 'fullstack_test') exists.
    3. Creates it if it's missing.

    Args:
        target_url: The full connection string for the test database we want to use.
                   (e.g. postgresql://user:pass@host:port/fullstack_test)
    """
    # 1. Parse the target URL to separate the server connection from the database name
    # Example: postgresql://user:pass@localhost:5432/fullstack_test
    # base_url -> postgresql://user:pass@localhost:5432
    # db_name -> fullstack_test
    base_url, db_name = target_url.rsplit("/", 1)

    # 2. Construct a connection URL to the administrative 'postgres' database
    # We need to connect to 'postgres' because we can't connect to a DB that doesn't exist yet.
    postgres_admin_url = f"{base_url}/postgres"

    try:
        # 3. Connect to the 'postgres' maintenance database
        # isolation_level="AUTOCOMMIT" is required because CREATE DATABASE cannot run inside a transaction block
        engine = create_engine(postgres_admin_url, isolation_level="AUTOCOMMIT")

        with engine.connect() as conn:
            # 4. Check if the target database exists
            result = conn.execute(
                text("SELECT 1 FROM pg_database WHERE datname = :dbname"),
                {"dbname": db_name},
            )
            exists = result.fetchone() is not None

            # 5. Create it if it doesn't exist
            if not exists:
                _ = conn.execute(text(f'CREATE DATABASE "{db_name}"'))
                print(f"✓ Created test database: {db_name}")

        engine.dispose()

    except (OperationalError, ProgrammingError) as e:
        # Log warning but don't crash - the test might fail later with a clearer error
        # or this might be a transient connection issue check handled elsewhere.
        print(f"Warning: Failed to ensure test database '{db_name}' exists: {e}")


def _clear_test_database(target_url: str) -> None:
    """Clears the test database by dropping and recreating the public schema.

    This ensures we start with a clean slate before migrations run.
    """
    try:
        # Connect to the target database
        engine = create_engine(target_url)
        with engine.connect() as conn:
            with conn.begin():
                _ = conn.execute(text("DROP SCHEMA public CASCADE"))
                _ = conn.execute(text("CREATE SCHEMA public"))
                _ = conn.execute(text("GRANT ALL ON SCHEMA public TO public"))
                _ = conn.execute(text("GRANT ALL ON SCHEMA public TO current_user"))

        engine.dispose()
        print("✓ Cleared test database")

    except (OperationalError, ProgrammingError) as e:
        print(f"Warning: Failed to clear test database: {e}")


def provide_postgres_container() -> Generator[str]:
    """Start a fresh PostgreSQL Docker container for testing.

    Yields:
        The connection URL to the test database inside the container.
    """
    # Start a standard Postgres container
    container = PostgresContainer("postgres:17", driver="psycopg2")

    # Configure for performance (disable durability since it's throwaway data)
    container = container.with_command(
        "postgres -c fsync=off -c synchronous_commit=off -c full_page_writes=off"
    )

    with container as postgres:
        # The container provides a default database (usually 'test' or 'postgres')
        # We simply return that URL. Since it's a fresh container, we don't need
        # to create a separate 'fullstack_test' DB, we can just use the default one.
        # But for consistency, we verify connection first.
        url = postgres.get_connection_url()

        # Wait for readiness
        engine = create_engine(url)
        with engine.connect() as conn:
            _ = conn.execute(text("SELECT 1"))

        yield url
