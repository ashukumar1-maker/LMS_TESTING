# Backend CD Tasks

Backend CD tasks are deployment-time tasks that run in the backend section of
the Argo deployment workflow. They replace the legacy Cloud Run CD jobs.

`infra/modules/kubernetes/config` owns the CD workflow child module and passes
the ordered task list into it. The environment roots currently pass a
`migrations` task into `kubernetes_config`; that task runs Alembic migrations
from `backend/src/cd_tasks/run_alembic_migrations.py`.

## Deployment Behavior

Backend CD tasks run only during `BACKEND_ONLY` and `FULL` workflow runs when
the backend image needs rollout. The backend branch order is:

1. Build and push the desired backend image if needed.
2. Run ordered backend CD tasks with that desired image.
3. Roll out the backend Deployment to that image.
4. Record final backend CD state.

If a backend CD task fails, rollout does not run and backend CD state is not
recorded.

Task-definition-only infrastructure changes do not execute the task
immediately. For example, adding a new task through Terraform will install it
during an `INFRA_ONLY` run, but the task will not run until the next
`BACKEND_ONLY` or `FULL` workflow where the backend image needs rollout.

## Runtime Access

Backend CD tasks are created by Argo as short-lived Kubernetes Jobs in the
backend namespace. Each task uses the backend runtime contract:

- Backend Kubernetes service account.
- `backend-env` ConfigMap for non-secret environment variables.
- External Secrets-managed backend Kubernetes Secret for sensitive environment
  variables, including `DATABASE_URL`.
- Cloud SQL Auth Proxy sidecar mounted at `/cloudsql`.
- Backend GCS bucket mounted at `/mnt/gcs` through GCS Fuse.
- The same desired backend image that will be rolled out after the tasks pass.

Public internet egress currently follows the cluster's general GKE egress path.
Static allowlisted backend egress is a separate follow-up from the Cloud Run CD
job migration.

## Registering A New Task

Add a Python module under `backend/src/cd_tasks/`. It should be executable with
`python -m` and should define a small `main()` entry point:

```python
from __future__ import annotations


def main() -> None:
    """Run the CD task."""
    ...


if __name__ == "__main__":
    main()
```

Register the task in each environment root through the `kubernetes_config`
module's `backend_cd_tasks` input:

```hcl
backend_cd_tasks = [
  {
    name                     = "migrations"
    python_module            = "src.cd_tasks.run_alembic_migrations"
    timeout_seconds          = 600
    max_retries              = 0
    ttl_seconds_after_finish = 86400
  },
  {
    name                     = "backfill"
    python_module            = "src.cd_tasks.run_backfill"
    timeout_seconds          = 900
    max_retries              = 1
    ttl_seconds_after_finish = 86400
  },
]
```

Task names must be lowercase DNS label segments. Timeout, retry count, and TTL
are explicit for each task. Only increase `max_retries` for tasks that are
explicitly idempotent and safe to run more than once.

## Operating Guidance

Keep deployment-time tasks small and necessary for rollout. Long backfills,
large external API fanout, destructive cleanup, or work that does not need to
block a new backend image should usually be a manual operation, an
application-managed worker flow, or a runbook instead of a CD task.
