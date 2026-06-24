"""Database access check for backend health probes."""

from __future__ import annotations

import logging
from typing import cast

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from src.get_async_db import AsyncSessionLocal

logger = logging.getLogger(__name__)


async def check_database_access() -> bool:
    """Check whether the backend can execute a trivial database query.

    Returns:
        True when the database accepts a simple query; otherwise False.
    """
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT 1"))
            value = cast("int", result.scalar_one())
            return value == 1
    except SQLAlchemyError:
        logger.exception("Backend health check failed database access")
        return False
