"""Shared pytest fixtures for backend tests."""

from __future__ import annotations

# ruff: noqa: I001
# This must be the first import to ensure AsyncSessionLocal is patched before it's imported elsewhere
from tests.fixtures.override_async_session_local import (
    override_async_session_local,
)
from tests.fixtures.client import client
from tests.fixtures.db_session import db_session
from tests.fixtures.migrate_test_db import migrate_test_db
from tests.fixtures.override_auth import override_auth
from tests.fixtures.override_get_async_db import override_get_async_db
from tests.fixtures.postgres_container import postgres_container

__all__ = [
    "client",
    "db_session",
    "migrate_test_db",
    "override_async_session_local",
    "override_auth",
    "override_get_async_db",
    "postgres_container",
]
