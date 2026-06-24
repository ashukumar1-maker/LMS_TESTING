"""Shared pytest configuration for backend tests."""

from __future__ import annotations

import os

# put a magic mock on all env vars in config.py so we can run tests without them
# Set environment variables before importing src.server (which imports config.py)
# This ensures Settings() can be instantiated without missing required env vars
_ = os.environ.setdefault(
    "DATABASE_URL", "postgresql://dev_user:dev_password@localhost:5432/fullstack_test"
)
_ = os.environ.setdefault("ENVIRONMENT", "test")
_ = os.environ.setdefault("GOOGLE_CLOUD_PROJECT", "test-project")
_ = os.environ.setdefault("AUTH_SERVICE_API_URL", "https://auth.test")
_ = os.environ.setdefault("AUTH_SERVICE_API_KEY", "test-api-key")
_ = os.environ.setdefault("MOUNTED_BACKEND_GCS_BUCKET_NAME", "test-bucket")
_ = os.environ.setdefault("BACKEND_BUCKET_MOUNT_PATH", "./simulated_bucket")

# Imports must come after env vars are set (Settings() is instantiated at import time)

# Import all fixtures to make them available to tests
from tests.fixtures import *  # noqa: E402,F403
