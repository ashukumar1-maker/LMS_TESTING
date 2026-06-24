"""Async utility functions for interacting with the mounted GCS bucket.

This module provides non-blocking file operations for the GCS bucket mounted
via GCS FUSE. All functions use aiofiles to avoid blocking the FastAPI event loop.
"""

from __future__ import annotations

import fnmatch
from pathlib import Path
from typing import TYPE_CHECKING

import aiofiles
import aiofiles.os

from src.config import settings

if TYPE_CHECKING:
    from collections.abc import AsyncGenerator, AsyncIterator


class PathTraversalError(Exception):
    """Raised when a path attempts to traverse outside the bucket directory."""

    def __init__(self, relative_path: str) -> None:
        """Build a path traversal error for a rejected relative path.

        Args:
            relative_path: User-provided path that resolved outside the bucket root.
        """
        super().__init__(
            f"Path '{relative_path}' attempts to traverse outside the bucket directory"
        )


def _resolve_path(relative_path: str) -> Path:
    """Resolves a relative path against the bucket mount path.

    Validates that the resolved path stays within the bucket directory
    to prevent path traversal attacks (e.g., "../../../etc/passwd").

    Args:
        relative_path: Path relative to the bucket mount point.

    Returns:
        The full resolved Path object.

    Raises:
        PathTraversalError: If the path attempts to escape the bucket directory.
    """
    bucket_root = Path(settings.BACKEND_BUCKET_MOUNT_PATH).resolve()
    full_path = (bucket_root / relative_path).resolve()

    if not full_path.is_relative_to(bucket_root):
        raise PathTraversalError(relative_path)

    return full_path


async def read_file(relative_path: str) -> bytes:
    """Reads a file from the mounted bucket.

    Args:
        relative_path: Path relative to the bucket mount point.

    Returns:
        The file contents as bytes.
    """
    full_path = _resolve_path(relative_path)
    async with aiofiles.open(full_path, "rb") as f:
        return await f.read()


async def write_file(relative_path: str, data: bytes) -> None:
    """Writes data to a file in the mounted bucket.

    Creates parent directories if they don't exist.

    Args:
        relative_path: Path relative to the bucket mount point.
        data: The bytes to write.
    """
    full_path = _resolve_path(relative_path)
    await aiofiles.os.makedirs(full_path.parent, exist_ok=True)
    async with aiofiles.open(full_path, "wb") as f:
        _ = await f.write(data)


async def delete_file(relative_path: str) -> None:
    """Deletes a file from the mounted bucket.

    Args:
        relative_path: Path relative to the bucket mount point.
    """
    full_path = _resolve_path(relative_path)
    await aiofiles.os.remove(full_path)


async def file_exists(relative_path: str) -> bool:
    """Checks if a file exists in the mounted bucket.

    Args:
        relative_path: Path relative to the bucket mount point.

    Returns:
        True if the file exists, False otherwise.
    """
    full_path = _resolve_path(relative_path)
    return await aiofiles.os.path.exists(full_path)


async def get_file_size(relative_path: str) -> int:
    """Gets the size of a file in bytes.

    Args:
        relative_path: Path relative to the bucket mount point.

    Returns:
        The file size in bytes.
    """
    full_path = _resolve_path(relative_path)
    stat_result = await aiofiles.os.stat(full_path)
    return stat_result.st_size


async def list_files(
    relative_path: str = "",
    pattern: str | None = None,
) -> list[str]:
    """Lists files in a directory within the mounted bucket.

    Args:
        relative_path: Path relative to the bucket mount point. Defaults to root.
        pattern: Optional glob pattern to filter files (e.g., "*.txt", "*.json").

    Returns:
        A list of file paths relative to the bucket mount point.
        Only files are returned, not directories.
    """
    full_path = _resolve_path(relative_path)
    entries = await aiofiles.os.listdir(full_path)

    files: list[str] = []
    for entry in entries:
        entry_path = full_path / entry
        if await aiofiles.os.path.isfile(entry_path):
            if pattern is None or fnmatch.fnmatch(entry, pattern):
                if relative_path:
                    files.append(f"{relative_path}/{entry}")
                else:
                    files.append(entry)

    return files


async def read_file_streaming(
    relative_path: str,
    chunk_size: int = 8192,
) -> AsyncGenerator[bytes]:
    """Reads a file in chunks as an async generator.

    Use this for large files to avoid loading the entire file into memory.

    Args:
        relative_path: Path relative to the bucket mount point.
        chunk_size: Size of each chunk in bytes. Defaults to 8192.

    Yields:
        Chunks of file data as bytes.
    """
    full_path = _resolve_path(relative_path)
    async with aiofiles.open(full_path, "rb") as f:
        while chunk := await f.read(chunk_size):
            yield chunk


async def write_file_streaming(
    relative_path: str,
    data_stream: AsyncIterator[bytes],
) -> None:
    """Writes data from an async iterator to a file.

    Use this for large files or when data is received in chunks.

    Args:
        relative_path: Path relative to the bucket mount point.
        data_stream: An async iterator yielding bytes chunks.
    """
    full_path = _resolve_path(relative_path)
    await aiofiles.os.makedirs(full_path.parent, exist_ok=True)
    async with aiofiles.open(full_path, "wb") as f:
        async for chunk in data_stream:
            _ = await f.write(chunk)
