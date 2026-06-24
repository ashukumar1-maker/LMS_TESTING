# Fullstack Template Guide

## Project Overview

- **Frontend**: React 19 + TypeScript + Vite 8 + Tailwind v4 + Ciridae UI shadcn registry
- **Backend**: FastAPI + PostgreSQL + SQLAlchemy
- **Infrastructure**: Terraform + GCP/Azure + Docker
- **Deployments**: Managed by Crucible; consult `CRUCIBLE_COMPATIBILITY.md` before changing Docker Compose, runtime ports, proxy/domain configuration, deployment env vars, or auth wiring.

## Quick Start

```bash
docker-compose up -d

# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

## Principles

1. **Ciridae UI first** — use the hosted Ciridae shadcn registry and local `components.json`.
2. **Semantic tokens only** — use tokens from `frontend/src/index.css`, such as `bg-background`, `text-foreground`, and `border-border`.
3. **Registry before local systems** — reusable UI belongs in the Ciridae UI source repository first, then this template consumes it through the hosted registry.
4. **Preserve platform behavior** — backend APIs, auth, Firebase, Sentry, PostHog, Docker, and deployment behavior should stay intact unless explicitly changed.
5. **One export, one name** — A file that exports a single function or component is named after that export, and every file is named prescriptively for the one thing it does (no `utils`/`helpers` junk drawers). One concern per file. Details in `backend/AGENTS.md` and `frontend/AGENTS.md`.
6. **Tests earn their place** — Test behavior, not implementation; no trivial or mock-heavy tests; a test should never be more complex than the code it covers. Details in `backend/tests/AGENTS.md`.

## Review Guidance

Review-specific guardrails and examples live in [REVIEW.md](./REVIEW.md), with scoped additions in [backend/REVIEW.md](./backend/REVIEW.md) and [frontend/REVIEW.md](./frontend/REVIEW.md). When you notice repeated mistakes, high-risk decisions that deserve careful review, or review-bot findings that should have been caught earlier, add or tighten the closest scoped rule instead of duplicating it across bot configs.

## Backend Development

**For ALL backend work, refer to: `backend/AGENTS.md`**

### API Structure

- FastAPI with async support
- PostgreSQL with SQLAlchemy ORM
- Alembic for migrations
- Pydantic for validation

### Authentication

- Ciridae Auth integration
- Token verification in `src/auth/verify_user.py`
- Protected routes using `Depends(verify_user)`

## Frontend Development

**Refer to: `frontend/AGENTS.md`, `frontend/STYLE_GUIDELINES.md`, `DESIGN.md`, and `CIRIDAE_PRECISION.md`.**

Key points:

- Tailwind v4 tokens live in `frontend/src/index.css`.
- shadcn/Ciridae registry config lives in `frontend/components.json`.
- Prefer lowercase imports like `@/components/ui/button`.
- Pull reusable UI from `https://ciridae-ui.ciridae.app/r`.
- **PostHog: ALL mutations must include capture events.**

## Infrastructure Development

See `infra/README.md` for Terraform and deployment details.

### Deployment-Time CD Jobs

- If a new deployment-time backend task must run during CD, refer to `infra/docs/backend-cd-tasks.md`.
- Use backend CD tasks carefully and only when no better option exists. Prefer normal application code paths, migrations, or explicit operational runbooks unless the task truly needs to run automatically during deployment with backend runtime access.

## WAF (Cloud Armor) Debugging

- Cloud Armor WAF protects the backend load balancer with OWASP CRS 3.3 stable rules (sensitivity 1).
- Request bodies are inspected up to 64KB; requests larger than 64KB are blocked with `403`.
- IP rate limiting: 1000 requests/minute per IP. Exceeding the limit returns `429`.
- HTTP method filtering is custom: `TRACE`, `CONNECT`, and `TRACK` are blocked; REST methods like `PUT`, `PATCH`, and `DELETE` are allowed.
- Cloud Armor Adaptive Protection (Layer 7 DDoS defense) is enabled on the backend policy.

### If It Fails in Deployed but Works Locally

1. **Check Cloud Armor logs** in Cloud Logging for the policy name, rule priority, and matched signature.
2. **Verify request size** (content-length); oversized requests are blocked before they reach Cloud Run.
3. **Look for missing CORS headers** on deny responses. The browser may report a CORS error even when the WAF returned `403`.
4. **Check for rate limit blocks**: `429` responses indicate the IP-based throttling rule triggered.
5. **Reproduce with curl** to see the true status code and headers:
   ```bash
   curl -i \
     -H "Origin: https://YOUR_FRONTEND_DOMAIN" \
     -H "Content-Type: application/json" \
     --data @payload.json \
     https://api.YOUR_DOMAIN/your/endpoint
   ```
6. **Tune for false positives** by reviewing the matched signature and adjusting WAF exclusions if needed.

## Pre-Commit Hooks

At the start of work, install pre-commit hooks so linting, formatting, type-checking, and secret detection run automatically on each commit:

```bash
cd backend && uv run pre-commit install
```

## Pre-Commit Dependency Check

Before committing, check for outdated dependencies in both backend and frontend:

```bash
# Backend (Python/uv)
cd backend && uv pip list --outdated

# Frontend (Node/yarn)
cd frontend && yarn outdated
```

Flag security-sensitive packages and major version bumps. Bump outdated packages in a separate commit/PR from feature work, running tests after each bump.
