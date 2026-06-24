"""Generate OpenAPI JSON schema from FastAPI application."""

import json
import sys
from pathlib import Path
from unittest.mock import MagicMock

# Add the backend directory to the path so we can import src modules
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

# Mock settings before importing server to avoid requiring environment variables
# MagicMock will handle all attribute accesses automatically
mock_settings = MagicMock()
# Only set SENTRY_URL to None to prevent Sentry initialization
mock_settings.SENTRY_URL = None
sys.modules["src.config"] = MagicMock()
sys.modules["src.config"].settings = mock_settings

from src.server import app  # noqa: E402

# Generate OpenAPI schema
openapi_schema = app.openapi()

# Write to backend/openapi.json
output_path = backend_dir / "openapi.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(openapi_schema, f, indent=2)

print(f"✓ Generated OpenAPI schema: {output_path}")
