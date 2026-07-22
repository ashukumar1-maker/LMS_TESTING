"""FastAPI application setup and global exception handlers."""

from __future__ import annotations

import logging

import sentry_sdk
import uvicorn
from fastapi import FastAPI, Request, status
from fastapi.exceptions import HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.config import settings
from src.routes.example_route import router as example_router
from src.routes.feedback import router as feedback_router
from src.routes.health import router as health_router
from src.routes.phase1 import router as phase1_router
from src.sentry_scrub import scrub_sentry_auth_headers

# Configure logger for this module
logger = logging.getLogger(__name__)

# Initialize Sentry
if (
    settings.SENTRY_URL and settings.SENTRY_URL != "-"
):  # "-" is the placeholder value for new secrets
    _ = sentry_sdk.init(
        dsn=settings.SENTRY_URL,
        send_default_pii=True,
        before_send=scrub_sentry_auth_headers,
        before_send_transaction=scrub_sentry_auth_headers,
        traces_sample_rate=0.1,
        environment=settings.ENVIRONMENT,
        profiles_sample_rate=0.1,
        profile_lifecycle="trace",
    )

app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)


# --- Middleware --- #

# TODO: Restrict origins for production
origins = ["*"]

app.add_middleware(
    CORSMiddleware,  # type: ignore[arg-type]
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Global Exception Handler --- #


@app.exception_handler(HTTPException)
# This should only be triggered by exceptions we've thrown ourseves
# and that do not contain sensitive information in the detail field
def http_exception_handler(
    request: Request,
    exc: HTTPException,
) -> JSONResponse:
    """Return sanitized responses for expected HTTP exceptions.

    Args:
        request: The incoming request that raised the exception.
        exc: The expected HTTP exception.

    Returns:
        A JSON response preserving the safe status, detail, and headers.
    """
    logger.warning(
        "HTTP Exception occurred - Status: %d, Method: %s, URL: %s, Detail: %s",
        exc.status_code,
        request.method,
        request.url,
        exc.detail,
    )

    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=exc.headers,
    )


@app.exception_handler(Exception)
def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Return sanitized responses for unexpected exceptions.

    Args:
        request: The incoming request that raised the exception.
        exc: The unexpected exception.

    Returns:
        A generic 500 JSON response that avoids leaking internal details.
    """
    logger.error(
        "Unhandled exception occurred - Method: %s, URL: %s, Exception: %s",
        request.method,
        request.url,
        exc,
        exc_info=(type(exc), exc, exc.__traceback__),
    )

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred on the server."},
    )


# --- Routers --- #


app.include_router(example_router)
app.include_router(feedback_router)
app.include_router(health_router)
app.include_router(phase1_router)


# --- Server Entrypoint --- #

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)  # noqa: S104
