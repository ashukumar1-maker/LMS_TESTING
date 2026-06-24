"""Mounted bucket access check for backend health probes."""

from __future__ import annotations

import logging
from pathlib import Path

import aiofiles.os

from src.config import settings

logger = logging.getLogger(__name__)


async def check_bucket_access() -> bool:
    """Check whether the configured backend bucket mount can be listed.

    Returns:
        True when the bucket mount path exists and can be listed; otherwise False.
    """
    bucket_path = Path(settings.BACKEND_BUCKET_MOUNT_PATH)

    try:
        _ = await aiofiles.os.listdir(str(bucket_path))
    except OSError:
        logger.exception("Backend health check failed bucket access")
        return False

    return True
