# Azure CD Steps

Provider-specific Argo `Template` fragments used by
`infra/modules/kubernetes/cd_workflow`.

These modules return Argo template objects through a `template` output. The
shared Kubernetes CD workflow composes those outputs into a single
`WorkflowTemplate` when `cloud = "azure"`.

Keep only Azure-specific commands here, such as ACR backend image builds, Azure
Storage static website uploads, and Azure CDN or Front Door invalidation. Shared
workflow steps such as source cloning, Terraform convergence, frontend builds,
and backend rollout stay in `infra/modules/kubernetes/cd_workflow`.

## Modules

| Module | Argo template name | Workflow task | Purpose |
| --- | --- | --- | --- |
| `build_and_push_backend_image_step` | `backend-build` | `backend-build` | Build and push the backend image through `az acr run` |
| `frontend_upload` | `frontend-upload` | `frontend-upload` | Sync built frontend assets into the `$web` static website container |
| `cdn_invalidate` | `cdn-invalidate` | `cdn-invalidate` | Placeholder until Azure Front Door or CDN invalidation is implemented |

## Wiring

`infra/modules/kubernetes/cd_workflow/provider_selected_step_templates.tf` instantiates the Azure
modules when `local.cloud == "azure"` and selects their `template` outputs into
`build_and_push_backend_image_step_template`, `upload_frontend_assets_step_template`, and
`invalidate_frontend_cache_step_template`.

Each step runs in the Argo workflow namespace under a Kubernetes service account
created by `infra/modules/azure/ci_cd`. Azure Workload Identity supplies the
federated token files and client IDs used by the Azure CLI login path in the
build and upload steps.

## Related Docs

- Shared workflow composition and deployment modes:
  `infra/modules/kubernetes/cd_workflow/README.md`
- Azure workflow identities and RBAC:
  `infra/modules/azure/ci_cd/README.md`
- Multi-cloud module layout: `infra/docs/multi-cloud-modules.md`
