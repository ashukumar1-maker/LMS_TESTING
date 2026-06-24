# Use Astral UV base image with Python pre-installed
FROM ghcr.io/astral-sh/uv:0.11.15-python3.13-trixie-slim

# Keep the virtualenv outside /app so Compose can bind-mount source without
# hiding or replacing container-built dependencies.
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=never
ENV UV_PROJECT_ENVIRONMENT=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy metadata and install dependencies (cached)
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# Copy application code
COPY . .

# Install the project into the environment
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

# Expose port
EXPOSE 8000

# Reset Astral UV default entrypoint so our CMD runs exactly as declared
ENTRYPOINT []

CMD ["/opt/venv/bin/uvicorn", "src.server:app", "--host", "0.0.0.0", "--port", "8000"]
