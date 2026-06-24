# Azure Deployment Module

This module composes the Azure substrate for `cloud = "azure"` environments.
AzureTest sources this module directly as `module "deployment"` so Azure roots
only require Azure providers.

The current implementation provisions the provider-level resources needed for
AzureTest:

- `../network`: VNet, AKS subnet, PostgreSQL delegated subnet, Private Endpoint subnet, and backend IP
- `../aks`: private AKS with OIDC issuer and Azure Workload Identity enabled
- Azure Monitor: Log Analytics workspace and AKS Container Insights addon
- `../database`: Azure Database for PostgreSQL Flexible Server with private VNet access
- `../storage`: backend container
- `../frontend`: Azure Storage static website support plus Azure Front Door
  profile, endpoint, origin, custom domain, and route
- `../bucket_for_tf_state`: Terraform state container
- `../backend`: Azure Container Registry with initial backend image bootstrap,
  backend identity, and External Secrets identity
- `../ci_cd`: deployment workflow managed identities and role assignments for
  Terraform apply, ACR Tasks backend builds, frontend static website uploads,
  and Front Door cache invalidation
- `../dns`: Azure DNS zone, backend API A record, frontend apex record, and
  Front Door custom domain validation record

Kubernetes workload manifests and Azure-specific Argo CD workflow steps live in
the shared Kubernetes/CD modules. Keep provider substrate resources here and
workflow rendering in `infra/modules/kubernetes` plus provider step fragments in
`infra/modules/azure/cd_steps`.

## Resource Flow

1. The deployment module creates a resource group and shared naming locals.
2. `../network` creates the VNet, subnets, and backend public IP.
3. The module creates a Log Analytics workspace for AKS Azure Monitor data.
4. `../aks` creates the private AKS cluster, enables the Azure Monitor addon,
   and exposes the OIDC issuer.
5. `../database` creates PostgreSQL private DNS, Flexible Server, and the app
   database.
6. The deployment module creates the shared Azure Storage account.
7. `../storage` creates the backend mounted app-data container.
8. `../frontend` enables static website hosting on the shared Storage account
   and creates the Front Door profile, endpoint, origin group, origin, custom
   domain, and route for frontend delivery.
9. `../bucket_for_tf_state` creates the Terraform state container.
10. The deployment module manages private Key Vault resources in `key_vault.tf`,
    writes deployment-owned secrets in `key_vault_secrets.tf`, and uses
    `key_vault_secret_writer_access.tf` to grant the active Terraform runner
    idempotent, non-destructive secret-write access before secrets are written.
11. `../backend` creates ACR, pushes the initial backend image, and creates
    backend/External Secrets workload identities.
12. `../ci_cd` creates deployment workflow identities and permissions.
13. This module grants AKS pull access to ACR and calls `../dns`.

## Important Inputs

- `azure_subscription_id`: Azure subscription where resources are created.
- `project_id`, `environment`, and `domain_name`: application identity and DNS
  naming inputs.
- `region`: Azure location, such as `eastus`.
- `private_endpoint_subnet_cidr`: CIDR range for private endpoints such as Key
  Vault.
- `backend_env_vars`, `backend_secret_env_vars`, and `frontend_env_vars`:
  application configuration maps.

Do not introduce a generic cloud account variable. Azure uses
`azure_subscription_id`; GCP uses `gcp_project_id`.

## Outputs

The output names intentionally match the environment deployment contract where
possible. Some GCP-specific outputs are `null` for Azure, such as GKE Fleet
fields. Azure-specific identity values are exposed through the existing workflow
identity map until the Kubernetes/CD workflow layer grows a cloud-neutral
contract.

## Current Limits

- Azure Kubernetes API access requires VNet connectivity because the control
  plane endpoint is private. Terraform running inside the Argo workflow uses
  in-cluster service account credentials so it can reach the private API server
  from AKS nodes.
- Azure backend builds use ACR Tasks and frontend deploys upload to the Storage
  static website `$web` container.
- Azure frontend delivery uses Front Door with a managed custom-domain
  certificate, and the CD workflow purges the Front Door endpoint after frontend
  uploads.
- External Crucible submission to private AKS may require matching
  `int-provisioning` support for a VNet-connected or Azure-supported submission
  path.
- Access canaries and critical alerting remain out of scope for AzureTest.
