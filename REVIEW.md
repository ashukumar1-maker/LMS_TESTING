# Review Guidelines

Review bots should focus on the PR diff and the code paths, contracts, and runtime behavior affected downstream by that diff. Scrutinize whether the PR makes out-of-scope changes. If review uncovers an unrelated bug, mention it only as optional follow-up context; do not make it the focus or block the PR unless the diff introduced, exposed, or worsened it.

Also apply scoped review rules when the PR touches those trees:

- [`backend/REVIEW.md`](./backend/REVIEW.md) for backend code, migrations, API contracts, Python tooling, and backend runtime configuration.
- [`frontend/REVIEW.md`](./frontend/REVIEW.md) for React, TypeScript, UI, API hooks, and frontend runtime configuration.

## Documentation Sync

- After code, contract, workflow, configuration, or runtime behavior changes, compare the diff against nearby documentation and generated contract files. Flag stale or missing updates to `README.md`, `AGENTS.md`, `REVIEW.md`, `CODE_REVIEW.md`, docs under `docs/`, API schemas, generated clients, deployment docs, and examples.
- Flag large architectural, convention, or workflow changes when the relevant `AGENTS.md`, scoped `REVIEW.md`, or project documentation is not updated to match the new guidance.
- When a PR changes review-bot guidance, verify every bot entry point still points at the same hierarchy so Devin Review, Cursor Bugbot, CodeRabbit, and humans do not drift.

When PR findings reveal a reusable review rule that is missing or unclear, suggest adding the concise rule to the closest scoped `REVIEW.md`.

## Naming, Complexity, And Typing

- Flag names that need a prose explanation to be understood. Prefer explicit domain names, even 4-5 words, over abbreviations, vague booleans, or internal jargon.
- Flag hard-to-follow code unless the PR explains why the complexity is required. Prefer deleting layers, naming the repeated concept, or extracting a small typed helper over hiding logic in generic utilities or hooks.
- Flag loose typing at boundaries. Parse unknown data once with Zod or Pydantic, use `Literal[...]` or discriminated unions for variants, and require values that every real caller must provide.

## Runtime And Infra

- Scrutinize Docker Compose, Vite config, Terraform, Cloud Build, deployment env vars, proxy/domain configuration, and other runtime configuration changes for downstream Crucible, Ghost Env, Hosted Workspace, and Lite Deployment impact.
- Treat `CRUCIBLE_COMPATIBILITY.md` as the source of truth for sensitive deployment surfaces. Flag PRs that touch `docker-compose.yml`, Docker startup scripts, Dockerfiles, `frontend/vite.config.ts`, Cloud Build, Terraform, runtime ports, Compose service names, health checks, proxy/domain behavior, auth wiring, CORS/frontend origins, `VITE_API_URL`, Crucible-provided env vars, or `BACKEND_BUCKET_MOUNT_PATH` without preserving or updating that compatibility contract.
- Do not accept hard-coded `localhost`, fixed public domains, single-environment callback URLs, Vite host/port/allowed-host changes, or renamed `backend`/`frontend` Compose services unless the PR updates and verifies Crucible/Ghost Env compatibility at the same time.
- Do not add lint, type, or tooling ignore statements in configuration without a narrow, reviewed reason captured in the PR.
