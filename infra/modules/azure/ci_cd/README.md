# Azure CI/CD Module

Creates Azure managed identities and role assignments for the future Argo-based
deployment workflow on AKS. This mirrors the GCP `ci_cd` module boundary.

## Responsibilities

- Defines Kubernetes service account names used by deployment workflow step instances.
- Creates one user-assigned managed identity per privileged workflow task.
- Creates federated identity credentials from AKS service account subjects to
  those managed identities.
- Grants Terraform apply resource management access, RBAC assignment access, and
  state storage access.
- Grants backend image build/read permissions against ACR, including the ACR
  Tasks control-plane access needed for `az acr run` workflow builds.
- Grants frontend deploy access only to the static website `$web` container.
- Grants frontend deploy read access to the Sentry auth token secret for source
  map upload workflows.
- Grants CDN/Front Door profile access at the environment resource group scope
  so future frontend invalidation steps can purge Azure CDN or Front Door
  endpoint caches.

## Key Inputs

- `oidc_issuer_url`: AKS OIDC issuer for federated identity credentials.
- `workflow_namespace`: Kubernetes namespace where Argo workflows run.
- `resource_group_id`: Scope for Terraform apply resource management, Terraform
  apply RBAC administration, and CDN invalidation identities.
- `storage_account_id`: Scope for Terraform state access.
- `frontend_static_website_container_id`: Scope for frontend static website
  uploads.
- `container_registry_id`: Scope for backend image build/read access.
- `sentry_auth_token_secret_id`: Scope for frontend Sentry auth token reads.

## Outputs

- `workflow_kubernetes_service_accounts`: Kubernetes service account names that
  Azure workflow templates should create/use.
- `workflow_step_service_account_identity_client_ids`: Azure client IDs for service account
  annotations.
- `workflow_required_parameters`: Deployment workflow parameter names.
- `crucible_deployment_contract_version`: Current external deployment contract
  version.

## Notes

This module does not install Argo or render workflow templates. Azure-specific
workflow steps live under `infra/modules/azure/cd_steps` and are selected by the
shared Kubernetes CD workflow wiring.

The Terraform apply identity receives both `Contributor` and `Role Based Access
Control Administrator` on the environment resource group. Contributor can
manage Azure resources but cannot create or replace Azure RBAC role assignments;
the RBAC administrator grant supplies the `Microsoft.Authorization/roleAssignments/*`
permissions needed for Terraform-managed `azurerm_role_assignment` resources.
