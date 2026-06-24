# Crucible Compatibility

This project is deployed by Crucible. Crucible creates Hosted Workspaces and Lite Deployments from this repository through the system in `../int-provisioning`, so the local Docker Compose contract is part of the deployment surface.

The core requirement is that Docker Compose must stay configurable enough for Crucible to proxy the app behind different public domains. Local development can use `localhost`, but Hosted Workspaces and Lite Deployments use separate frontend and backend hostnames supplied by Crucible.

## Docker Compose Contract

`docker-compose.yml` must remain compatible with Crucible-managed Hosted Workspaces and Lite Deployments:

- `docker compose up` must build and start the application from the repository root.
- The backend service must listen on `0.0.0.0:8000` inside the container and publish port `8000`.
- The frontend service must listen on `0.0.0.0:3000` inside the container and publish port `3000`.
- The frontend must be able to reach the backend through externally supplied `VITE_API_URL`.
- The backend must accept externally supplied frontend origins/domains through `FRONTEND_URL` and/or `CORS_ALLOWED_ORIGINS`.
- The backend `/health` endpoint must continue to work on port `8000`.
- The frontend health check must continue to work on port `3000`.

Do not rename or remove the `backend` and `frontend` Compose services unless the Crucible deployment integration is updated at the same time.

Do not hard-code `localhost`, fixed domains, or single-environment callback URLs in Docker startup scripts or application code. Any URL that differs between local development and Crucible deployments must remain configurable by environment variable.

For local Compose runs, if `BACKEND_HOST_PORT` changes the backend host port, the frontend's default `VITE_API_URL` must derive from that same value. An explicit `VITE_API_URL` should still take precedence.

## Vite Dev Server Configuration

`frontend/vite.config.ts` is part of the deployment surface for Hosted Workspaces and Lite Deployments.

The Vite dev server must remain reachable through Docker Compose and Crucible-managed proxy domains:

- The dev server must bind outside the container through `server.host = "::"` or equivalent.
- The frontend must continue serving on container port `3000`.
- Vite must allow Crucible-generated hostnames through `server.allowedHosts = true` or an explicit allowlist that includes those hostnames.

Do not change Vite host, port, or allowed-host behavior unless the Docker Compose contract and Crucible routing are updated and tested at the same time.

Do not solve backend URL or deployment-domain differences in `vite.config.ts`. Use `VITE_API_URL` and deployment-provided environment variables instead.

## Environment Variables

Crucible populates Hosted Workspaces and Lite Deployments from this project's dev environment and then applies overrides before starting the environment. The application must tolerate these env vars being provided by the deployment system rather than only by local `.env` files.

Any new environment variable required for the app to operate must be added manually in Crucible before code depending on it is deployed. Basic platform env vars such as LLM Gateway, Auth Service, PostHog, and Sentry settings are already expected to exist in Crucible; new app-specific required env vars are not automatic.

Backend env vars that must keep working:

- `DATABASE_URL`
- `GOOGLE_CLOUD_PROJECT`
- `AUTH_SERVICE_API_URL`
- `AUTH_SERVICE_API_KEY`
- `ENVIRONMENT`
- `LLM_GATEWAY_ENDPOINT`
- `LLM_GATEWAY_API_KEY`
- `MOUNTED_BACKEND_GCS_BUCKET_NAME` (optional outside GCP)
- `BACKEND_BUCKET_MOUNT_PATH`
- `FRONTEND_URL`
- `CORS_ALLOWED_ORIGINS`

Frontend env vars that must keep working:

- `VITE_API_URL`
- `VITE_ENVIRONMENT`
- `VITE_PROJECT_ID`
- `VITE_IDENTITY_PLATFORM_API_KEY`
- `VITE_IDENTITY_PLATFORM_AUTH_DOMAIN`
- `VITE_IDENTITY_PLATFORM_PROJECT_ID`
- `VITE_IDENTITY_PLATFORM_STORAGE_BUCKET`
- `VITE_IDENTITY_PLATFORM_MESSAGING_SENDER_ID`
- `VITE_IDENTITY_PLATFORM_APP_ID`
- `VITE_AUTH_SERVICE_FRONTEND_URL`
- `VITE_POSTHOG_API_KEY`
- `VITE_POSTHOG_HOST`
- `VITE_SENTRY_DSN`

Crucible automatically sets `VITE_API_URL` to the deployed backend URL. Local Docker Compose derives its default `VITE_API_URL` from `BACKEND_HOST_PORT`. Do not hard-code localhost-only backend URLs in frontend code or Docker startup scripts.

## Auth Compatibility

Crucible injects sandbox or production Identity Platform values into frontend env vars based on the selected auth type. Auth changes must preserve:

- Firebase/Identity Platform configuration through `VITE_IDENTITY_PLATFORM_*`.
- Auth service redirect and UI integration through `VITE_AUTH_SERVICE_FRONTEND_URL`.
- Backend token verification through `AUTH_SERVICE_API_URL` and `AUTH_SERVICE_API_KEY`.
- All redirect URLs must be authorized in Auth. Crucible automatically authorizes redirect URLs for every deployment and hosted workspace it creates.

## Backend Storage Path

Crucible can override `BACKEND_BUCKET_MOUNT_PATH` for Hosted Workspaces and Lite Deployments. Backend code must treat it as configurable and must not assume a fixed local path.
