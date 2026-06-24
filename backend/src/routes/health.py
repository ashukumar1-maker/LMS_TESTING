"""Health check API route."""

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from src.health_checks.check_bucket_access import check_bucket_access
from src.health_checks.check_database_access import check_database_access

router = APIRouter()


class HealthChecks(BaseModel):
    """Dependency checks included in the health response."""

    database: bool
    bucket: bool


class HealthResponse(BaseModel):
    """Response payload for service health checks."""

    healthy: bool
    checks: HealthChecks


@router.get("/health")
async def health_route_handler(response: Response) -> HealthResponse:
    """Return service health including database and bucket access.

    Args:
        response: FastAPI response object used to set unhealthy status codes.

    Returns:
        A payload indicating the service health status.
    """
    checks = HealthChecks(
        database=await check_database_access(),
        bucket=await check_bucket_access(),
    )
    healthy = checks.database and checks.bucket

    if not healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return HealthResponse(healthy=healthy, checks=checks)
