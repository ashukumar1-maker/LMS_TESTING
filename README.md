# provana-testing

This is a template for fullstack web applications deployed on GCP and authenticated through Ciridae Auth.

It includes:

- FastAPI backend with PostgreSQL and SQLAlchemy
- React 19 + TypeScript frontend powered by Vite 8
- Ciridae UI shadcn registry integration with Tailwind v4
- GCP infrastructure through Terraform
- Docker Compose for local development
- Ciridae Auth, PostHog, and Sentry integration

## Ciridae UI

The frontend has been reset to the Ciridae UI baseline. The starter app is intentionally minimal: authenticated users see a blank page that says `FULLSTACK TEMPLATE 1`.

Future product UI should come from the Ciridae UI registry:

```bash
cd frontend
npx shadcn@latest add https://ciridae-ui.ciridae.app/r/button.json
npx shadcn@latest add @ciridae/button
```

The local design-system contract is:

- `frontend/components.json` for shadcn and Ciridae registry wiring
- `frontend/src/index.css` for Tailwind v4 tokens, fonts, themes, density, and motion
- root `DESIGN.md` and `CIRIDAE_PRECISION.md` for agent and developer design guidance

Reusable UI should be built in the Ciridae UI source repository, registered there, and consumed here through the hosted registry.

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- [uv](https://docs.astral.sh/uv/)
- [yarn](https://yarnpkg.com/)

### Local Setup

```bash
./local_setup.sh
docker-compose up -d
```

Services:

- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8000`
- API docs: `http://localhost:8000/docs`

If a default host port is already in use, override the host-side port while preserving the container port:

```bash
POSTGRES_HOST_PORT=15432 BACKEND_HOST_PORT=18000 FRONTEND_HOST_PORT=13000 docker-compose up -d
```

The `frontend.environment.VITE_API_URL` entry in `docker-compose.yml` is `${VITE_API_URL:-http://localhost:${BACKEND_HOST_PORT:-8000}}`: if `VITE_API_URL` is unset, Compose constructs `http://localhost:<BACKEND_HOST_PORT>`, and `BACKEND_HOST_PORT` itself defaults to `8000` when unset.

Stop services:

```bash
docker-compose down
```

Test credentials: `test@ciridae.com` / `testtest`

## Development

```bash
docker-compose logs -f frontend
docker-compose restart frontend
docker-compose up -d --build
docker-compose exec db psql -U dev_user -d fullstack_dev
```

Backend code changes reload the FastAPI server. Frontend code changes trigger Vite HMR.

## Checks

Frontend:

```bash
cd frontend
yarn lint
yarn typecheck
yarn themecheck
yarn format:check
yarn build
```

Backend:

```bash
cd backend
uv run ruff check
uv run ruff format --check
uv run basedpyright
```

## Pre-Commit Hooks

Install hooks:

```bash
cd backend
uv sync
uv run pre-commit install
```

Security hooks block commits if secrets are detected. Code quality hooks warn locally but CI should still be kept green.

## Environment Variables

Backend variables are managed through `backend/src/config.py`.

Frontend variables must start with `VITE_` and are accessed with `import.meta.env`.

For deployed infrastructure variables, see `infra/docs/environment-variables.md`.

## Key Docs

| Doc | Purpose |
| --- | --- |
| `AGENTS.md` | Repo-wide agent guidance |
| `frontend/AGENTS.md` | Frontend implementation guidance |
| `frontend/STYLE_GUIDELINES.md` | Ciridae UI style summary |
| `DESIGN.md` | Ciridae UI implementation rules |
| `CIRIDAE_PRECISION.md` | Ciridae design north star |
| `backend/AGENTS.md` | Backend patterns |
