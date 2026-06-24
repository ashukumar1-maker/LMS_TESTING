# GCP CD Steps

Provider-specific Argo `Template` fragments used by
`infra/modules/kubernetes/cd_workflow`.

These modules return Argo template objects through a `template` output. The
shared Kubernetes CD workflow composes those outputs into a single
`WorkflowTemplate` when `cloud = "gcp"`.

Keep only GCP-specific commands here, such as Artifact Registry backend image
pushes, GCS frontend uploads, and Cloud CDN invalidation. Shared workflow steps
such as source cloning, Terraform convergence, frontend builds, and backend
rollout stay in `infra/modules/kubernetes/cd_workflow`.

## Modules

| Module | Argo template name | Workflow task | Purpose |
| --- | --- | --- | --- |
| `build_and_push_backend_image_step` | `backend-build` | `backend-build` | Build and push the backend image with Kaniko |
| `frontend_upload` | `frontend-upload` | `frontend-upload` | Rsync built frontend assets into the GCS frontend bucket |
| `cdn_invalidate` | `cdn-invalidate` | `cdn-invalidate` | Invalidate the frontend URL map CDN cache |

## Wiring

`infra/modules/kubernetes/cd_workflow/provider_selected_step_templates.tf` instantiates the GCP
modules when `local.cloud == "gcp"` and selects their `template` outputs into
`build_and_push_backend_image_step_template`, `upload_frontend_assets_step_template`, and
`invalidate_frontend_cache_step_template`.

Each step runs in the Argo workflow namespace under a Kubernetes service account
created by `infra/modules/gcp/ci_cd`. GCP Workload Identity supplies the
credentials used by Kaniko, `gsutil`, and `gcloud` in these steps.

## Related Docs

- Shared workflow composition and deployment modes:
  `infra/modules/kubernetes/cd_workflow/README.md`
- GCP workflow identities and IAM:
  `infra/modules/gcp/ci_cd/README.md`
- Multi-cloud module layout: `infra/docs/multi-cloud-modules.md`
