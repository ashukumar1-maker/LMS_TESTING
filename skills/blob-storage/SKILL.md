---
name: blob-storage
description: Skill and best practices for interacting with the blob storage mounted bucket setup within this system.
---

# Blob Storage (GCS Mounted Bucket)

## When to Use

Use this bucket for **any file that needs to be persisted** - images, PDFs, user uploads from the frontend, generated documents, or any other binary/file data. The bucket is already configured and ready to use.

## How It Works

The GCS bucket is mounted directly to the Cloud Run container using GCS FUSE. This means you interact with it like a regular filesystem. No GCS client libraries or special APIs required.

**Important:** Since FastAPI runs on an async event loop, you must use async file operations to avoid blocking. The `bucket_utils` module handles this for you.

## Best Practice: Always Use `bucket_utils`

**Always use the utility functions in `src/bucket_utils.py`** for all bucket operations. These utilities:

1. Use `aiofiles` for non-blocking async I/O
2. Automatically resolve paths against the bucket mount path
3. **Protect against path traversal attacks** (e.g., `../../../etc/passwd`)
4. Create parent directories automatically when writing files

```python
from src.bucket_utils import (
    read_file,
    write_file,
    delete_file,
    file_exists,
    list_files,
    get_file_size,
    read_file_streaming,
    write_file_streaming,
    PathTraversalError,
)
```

**Do NOT** use raw filesystem operations like `open()`, `Path.read_bytes()`, or `os.path.exists()` - these block the event loop and lack security protections.

## Available Functions

### Basic CRUD Operations

```python
# Read a file
content: bytes = await read_file("users/123/document.pdf")

# Write a file (creates parent directories automatically)
await write_file("users/123/document.pdf", pdf_bytes)

# Check if a file exists
exists: bool = await file_exists("users/123/document.pdf")

# Delete a file
await delete_file("users/123/document.pdf")

# Get file size in bytes
size: int = await get_file_size("users/123/document.pdf")
```

### Listing Files

```python
# List all files in a directory
files: list[str] = await list_files("users/123/uploads")

# List files matching a pattern
pdfs: list[str] = await list_files("users/123/uploads", pattern="*.pdf")
```

### Streaming (for Large Files)

Use streaming functions when dealing with large files to avoid loading the entire file into memory:

```python
# Read file in chunks
async for chunk in read_file_streaming("users/123/large_video.mp4"):
    # Process each chunk
    await response.write(chunk)

# Write from an async iterator
await write_file_streaming("users/123/large_video.mp4", upload_chunks)
```

## Example: FastAPI Endpoint

```python
from fastapi import APIRouter, Depends, HTTPException, UploadFile

from src.auth.verify_user import verify_user
from src.bucket_utils import file_exists, read_file, write_file

router = APIRouter()


@router.post("/upload/{filename}")
async def upload_file(
    filename: str,
    file: UploadFile,
    user_id: str = Depends(verify_user),
) -> dict[str, str]:
    """
    Uploads a file to the user's storage directory.

    Args:
        filename: Name for the uploaded file.
        file: The uploaded file.
        user_id: The authenticated user's ID.

    Returns:
        A dict containing the stored file path.
    """
    relative_path = f"users/{user_id}/uploads/{filename}"
    content = await file.read()
    await write_file(relative_path, content)
    return {"path": relative_path}


@router.get("/download/{filename}")
async def download_file(
    filename: str,
    user_id: str = Depends(verify_user),
) -> bytes:
    """
    Downloads a file from the user's storage directory.

    Args:
        filename: Name of the file to download.
        user_id: The authenticated user's ID.

    Returns:
        The file contents.

    Raises:
        HTTPException: If the file is not found.
    """
    relative_path = f"users/{user_id}/uploads/{filename}"

    if not await file_exists(relative_path):
        raise HTTPException(status_code=404, detail="File not found")

    return await read_file(relative_path)
```

## Security: Path Traversal Protection

The `bucket_utils` functions automatically protect against path traversal attacks. If a malicious path is provided (e.g., from user input), a `PathTraversalError` is raised:

```python
from src.bucket_utils import read_file, PathTraversalError

try:
    # This will raise PathTraversalError
    content = await read_file("../../../etc/passwd")
except PathTraversalError:
    # Handle the security violation
    raise HTTPException(status_code=400, detail="Invalid file path")
```

Paths that attempt to escape the bucket directory are blocked:
- `../../../etc/passwd` - parent directory traversal
- `/etc/passwd` - absolute paths
- `foo/../../bar` - hidden traversal in nested paths

## Configuration

The mount path is configured via environment variables:

| Environment Variable | Description | Example Value |
|---------------------|-------------|---------------|
| `BACKEND_BUCKET_MOUNT_PATH` | Path where the GCS bucket is mounted | `/mnt/gcs` (prod) or `./simulated_bucket` (local) |
| `MOUNTED_BACKEND_GCS_BUCKET_NAME` | Name of the GCS bucket | `my-project-dev-storage` |

## Local Development

For local development, the bucket mount path defaults to `./simulated_bucket` (a local directory). This allows you to develop and test file operations without needing access to the actual GCS bucket.

```bash
# In backend/.env
BACKEND_BUCKET_MOUNT_PATH="./simulated_bucket"
```

The simulated bucket directory is git-ignored, so any files you create during local development won't be committed.
