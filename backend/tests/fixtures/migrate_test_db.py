"""Alembic migration fixture for backend integration tests."""

import os

import pytest
from alembic.config import Config

from alembic import command


@pytest.fixture(scope="session", autouse=True)
def migrate_test_db(postgres_container: str) -> None:
    """Set up test database and run migrations once per test session.

    This fixture automatically:
    1. Runs Alembic migrations to set up the schema

    The actual database creation is handled by the postgres_container fixture.

    This makes test setup fully automatic - developers just run pytest with
    no manual database creation required.
    """
    target_db_url = postgres_container

    # Get path to alembic.ini relative to the backend directory
    # We are in backend/tests/fixtures/migrate_test_db.py
    # Need to go up to backend/
    current_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(os.path.dirname(current_dir))
    ini_path = os.path.join(backend_dir, "alembic.ini")

    # Set DATABASE_URL to test database for migrations
    os.environ["DATABASE_URL"] = target_db_url

    # Create Alembic config and override the database URL
    alembic_config = Config(ini_path)
    alembic_config.set_main_option("sqlalchemy.url", target_db_url)

    # Run migrations to head
    command.upgrade(alembic_config, "head")
