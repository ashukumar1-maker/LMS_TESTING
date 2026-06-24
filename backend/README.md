# Ciridae Fullstack Template Backend

## Overview

This is a simple backend for the Ciridae Fullstack Template project. It is a simple HTTP server that uses the Google Cloud Run service to host the backend.

## Development Setup

### Using Docker Compose (Recommended)

The easiest way to run the backend is using Docker Compose from the project root:

```bash
# From the project root directory
docker-compose up -d

# The backend will be available at http://localhost:8000
# API documentation at http://localhost:8000/docs
```

Docker Compose provides:
- PostgreSQL database (automatically configured)
- Hot reloading for code changes
- Proper networking between services
- Environment variable management

To view backend logs:
```bash
docker-compose logs -f backend
```

### Manual Setup (Alternative)

If you need to run the backend manually:

1. Install dependencies:
```bash
uv sync
```

2. Set up environment variables (see below) **including DATABASE_URL**

3. Run the server:
```bash
uv run uvicorn src.server:app --reload
```

## Environment Variables

### Docker Compose Development

When using Docker Compose, the essential environment variables are automatically configured:
- `DATABASE_URL` - Set to use the PostgreSQL container
- `CORS_ALLOWED_ORIGINS` - Set to "*" for development

Additional environment variables can be configured in `backend/.env`. Copy the example file and update with your values:

```bash
cp .env.example .env
# Then edit .env with your actual values
```

### Environment Variables

For production deployments, configure these variables:

- **`GOOGLE_CLOUD_PROJECT`** - Google Cloud Project ID where the backend is deployed
  - Used for accessing GCP services and resources
  - Example: `my-project-id`

- **`AUTH_SERVICE_BACKEND_URL`** - Base URL of the authentication service
  - Used to verify user tokens and check access permissions
  - Example: `https://api.auth.sandbox.ciridae.app`

- **`PROJECT_ID`** - Unique identifier for this project within the auth service
  - Used when making requests to the auth service to verify user access
  - Must match a project configured in the auth service
  - Example: `int-fullstacktemplate-1`

- **`MOUNTED_BACKEND_GCS_BUCKET_NAME`** - Optional name of the Google Cloud Storage bucket
  - Bucket that gets mounted to the backend service for file storage in GCP
  - Can be omitted by non-GCP deployments that provide `BACKEND_BUCKET_MOUNT_PATH`
  - Example: `my-project-backend-storage`

- **`BACKEND_BUCKET_MOUNT_PATH`** - Local filesystem path where GCS bucket is mounted
  - Path inside the container where the GCS bucket is accessible
  - For local development, can be a simulated directory
  - Example: `/mnt/gcs` (production) or `/simulated_bucket` (local)

### Example .env file

See `.env.example` for a complete example with all available environment variables.

