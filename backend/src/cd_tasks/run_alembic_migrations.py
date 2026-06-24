"""Deployment task for applying Alembic migrations."""

from __future__ import annotations

import os
from pathlib import Path

from alembic.config import Config

from alembic import command

ALEMBIC_REVISION = "head"


class MissingDatabaseUrlError(RuntimeError):
    """Raised when the migration task is missing its database connection URL."""

    def __init__(self) -> None:
        """Build the missing database URL error."""
        super().__init__("DATABASE_URL must be set to run migrations.")


def main() -> None:
    """Run all pending Alembic migrations."""
    _validate_database_url_is_configured()
    command.upgrade(_get_alembic_config(), ALEMBIC_REVISION)


def _validate_database_url_is_configured() -> None:
    """Ensure Alembic can read a non-empty DATABASE_URL during environment setup.

    Raises:
        MissingDatabaseUrlError: If DATABASE_URL is not set or is empty.
    """
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise MissingDatabaseUrlError


def _get_alembic_config() -> Config:
    """Build the Alembic configuration for the backend project.

    Returns:
        A configured Alembic Config instance.
    """
    backend_root = Path(__file__).resolve().parents[2]
    return Config(backend_root / "alembic.ini")


if __name__ == "__main__":
    main()
