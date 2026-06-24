"""Runtime configuration loaded from environment variables."""

from __future__ import annotations

from typing import ClassVar

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from the environment."""

    DATABASE_URL: str
    GOOGLE_CLOUD_PROJECT: str

    AUTH_SERVICE_API_URL: str
    AUTH_SERVICE_API_KEY: str

    ENVIRONMENT: str

    # Sentry configuration
    SENTRY_URL: str | None = None

    # Database connection pool configuration
    DB_POOL_SIZE: int = 2  # Number of connections to keep in the pool
    DB_MAX_OVERFLOW: int = 0  # Number of extra connections allowed above pool size

    # GCS bucket configuration
    # Optional name of the GCS bucket mounted to the backend service.
    MOUNTED_BACKEND_GCS_BUCKET_NAME: str | None = None
    # Path where the object storage bucket is mounted in the container.
    BACKEND_BUCKET_MOUNT_PATH: str

    model_config: ClassVar[SettingsConfigDict] = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )


settings = Settings()  # pyright: ignore[reportCallIssue]
