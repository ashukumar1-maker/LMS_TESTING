"""Tests for the health route."""

from http import HTTPStatus
from pathlib import Path

import pytest
from httpx import AsyncClient

from src.config import settings


@pytest.mark.asyncio
async def test_health_endpoint(
    client: AsyncClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Return healthy when the database and bucket mount are reachable."""
    monkeypatch.setattr(settings, "BACKEND_BUCKET_MOUNT_PATH", str(tmp_path))

    response = await client.get("/health")

    assert response.status_code == HTTPStatus.OK
    assert response.json() == {
        "healthy": True,
        "checks": {
            "database": True,
            "bucket": True,
        },
    }
