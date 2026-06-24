# GCP CDN Invalidate CD Step

Defines the GCP-specific Argo `Template` for the `cdn-invalidate` workflow
task. This step invalidates the frontend Cloud CDN cache after a successful
frontend upload.

## Responsibilities

- Runs `gcloud compute url-maps invalidate-cdn-cache` for the frontend URL map.
- Invalidates all paths with `/*` so updated static assets are served promptly.
- Targets the configured GCP project explicitly with `--project`.

## Workflow Integration

- Argo template name: `cdn-invalidate`
- DAG task name: `cdn-invalidate`
- Runs after `frontend-upload` succeeds.
- Runs only in `FRONTEND_ONLY` or `FULL` deployment modes when
  `frontend-deploy-needed` is `true`.
- Successful completion is required before `record-final-frontend-cd-state`.

## Key Inputs

- `step_service_account_name`: Kubernetes service account used by the Argo step.
  Wired from the `cdn_invalidator` workflow identity in
  `infra/modules/gcp/ci_cd`.
- `frontend_url_map_name`: Compute URL map attached to the frontend load
  balancer. Wired from the shared CD workflow module.
- `gcp_project_id`: GCP project that owns the URL map.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

The step uses the `gcr.io/google.com/cloudsdktool/cloud-sdk:slim` image and
relies on GCP Workload Identity for Compute API access. The `cdn_invalidator`
service account receives the URL map invalidation permissions in
`infra/modules/gcp/ci_cd`.

Invalidation is scoped to the frontend URL map created by
`infra/modules/gcp/frontend`, not the backend load balancer.
