# Infrastructure Operations Guide for Agents

## Project Context
This is a full-stack template deployed through Terraform on GCP and Azure with:
- **Production URL**: `{PRODICUTION_URL}` (HTTPS with DNSSEC)
- **API Endpoint**: `api.{PRODICUTION_URL}`
- **Auth Provider**: External auth service at `ciridae-auth-dev`
- **Project Pattern**: `{PROJECT_ID}-{environment}`
- **Environment**: `{environment}`

## Common Operations

### First-Time Setup

- Ensure the environment being used has terraform.auto.tfvars file with the following variables:
  - project_id
  - cloud ("gcp" or "azure")
  - environment
  - domain_name (e.g., "{DOMAIN_NAME}")
  - gcp_project_id for GCP environments, or azure_subscription_id for Azure environments
  
Note: The following variables have defaults but can be overridden if needed:
  - `region` (default: "us-central1")
  - `is_dev` (default: true for dev, false for staging/prod)
  - Identity Platform/Firebase configuration:
    - `identity_platform_api_key`
    - `identity_platform_auth_domain`
    - `identity_platform_project_id`
    - `identity_platform_storage_bucket`
    - `identity_platform_messaging_sender_id`
    - `identity_platform_app_id`
    - `auth_service_frontend_url`

```bash

cd infra/environments/{environment}
# Create secrets file (git-ignored)
terraform init
terraform plan
# Get user approval before apply
```

### Checking Infrastructure State
```bash
# See what's deployed
terraform state list | grep -E "(kubernetes_|google_sql_database)"

# Check specific resource details
terraform state show 'module.kubernetes_config.kubernetes_deployment_v1.backend'

# Verify DNS configuration
terraform output dns_nameservers
terraform output ds_record_values
```

### Making Changes
```bash
# Always format first
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with specific targets if needed
terraform plan -target='module.deployment.module.backend_service'
```

- If terraform plan indicates that certain resources will be destoryed, point this out to the user

### Managing Environment Variables

The infrastructure supports three types of environment variables that can be configured in `terraform.auto.tfvars`:

- **backend_env_vars** - Non-sensitive backend configuration
- **backend_secret_env_vars** - Sensitive backend values (stored in Secret Manager)
- **frontend_env_vars** - Frontend build-time variables (must start with VITE_)

For detailed instructions, see the **[Environment Variables Guide](./docs/environment-variables.md)**.

Quick example:
```bash
cd infra/environments/dev
uv run ../../scripts/pullstate.py
# Edit terraform.auto.tfvars to add variables
terraform apply
uv run ../../scripts/pushstate.py
```

## Architecture Decisions & Gotchas

### Known Issues & Workarounds
1. **GKE Private Control Plane**: Use Connect Gateway for Terraform, CD, and troubleshooting access.
2. **Backend CD Tasks**: Deployment-time backend tasks run through the Argo workflow backend branch and only execute when a backend deployment leg runs.
3. **Argo Bootstrap**: First-time setup applies the cloud substrate, Kubernetes extensions, and deployment workflow config; the Argo workflow runs normal convergence after it exists.
4. **DNS Propagation**: Can take up to 48h - use `dig @8.8.8.8` to check Google's view

### Kubernetes Infrastructure
- The Terraform stack uses Kubernetes as the active backend runtime: GKE for GCP environments and AKS for Azure environments. Deployment-time backend tasks also run in-cluster through Argo.
- GKE is private and VPC-native. Nodes use the GKE subnet primary range, pods use the pod secondary range, and Kubernetes services use the service secondary range.
- AzureTest uses AKS with a private control plane endpoint, Azure Workload Identity, Azure Container Registry, Azure PostgreSQL Flexible Server, Azure Key Vault, Azure Blob Storage, Azure Front Door for frontend delivery, and Azure DNS.
- Private GKE nodes use a separate auto-allocated Cloud NAT for general internet access, such as pulling public Helm chart images. Do not use this as the backend static egress contract.
- Argo runs the steady-state infrastructure and code deployment workflow. Its Terraform task preserves the phased apply order: `module.deployment`, `module.kubernetes_crds`, then full apply. The CD workflow module is nested under `module.kubernetes_config`.
- Connect Gateway is the expected GKE access path for deployment tooling and local troubleshooting because the cluster control plane uses a private endpoint.
- For private AKS clusters, local `kubectl` and Kubernetes automation must run from inside the VNet, over VPN/peering, or via an Azure-supported command path.

### Integration Points
- **Frontend → Backend**: Via `VITE_API_URL` environment variable
- **Frontend → Auth Service**: Via `VITE_IDENTITY_PLATFORM_*` environment variables (configured in Terraform)
- **Frontend Delivery**: GCP uses Cloud Storage and Cloud CDN; Azure uses Storage static website hosting behind Azure Front Door with Azure DNS custom-domain records.
- **Backend → Database**: GCP uses Cloud SQL proxy on localhost:5432; Azure uses private PostgreSQL Flexible Server DNS.
- **Backend → Storage**: GCP uses the mounted GCS bucket contract; Azure exposes `AZURE_STORAGE_ACCOUNT_NAME` and `AZURE_STORAGE_CONTAINER_NAME` for Blob storage.
- **Backend → Auth Service**: Via `AUTH_SERVICE_BACKEND_URL` environment variable
- **Backend → Secrets**: GCP uses Secret Manager; Azure uses private Key Vault plus External Secrets.
- **Container Images**: GCP uses Artifact Registry; Azure uses Azure Container Registry.
- **CI/CD → Services**: Via the Terraform-managed Argo `WorkflowTemplate` and its required workflow parameters
- **CI/CD → GKE**: Via GKE Fleet Connect Gateway using Terraform outputs such as `gke_fleet_membership_name` and `gke_connect_gateway_host`
- **CI/CD → AKS**: Via Azure Workload Identity client IDs exposed in Terraform outputs. Azure CD is still being completed and should follow the Azure-specific tickets.

## Debugging Common Issues

### Trying to create an existing resource

Import the resource into the state
```bash
terraform import 'module.kubernetes_config.kubernetes_deployment_v1.backend' backend/backend
```

### DNS Not Resolving
```bash
# Check nameservers match
terraform output dns_nameservers
dig NS {DOMAIN_NAME}

# Verify DNSSEC chain
dig +dnssec {DOMAIN_NAME}
```

## Environment Strategy
- **dev**: Full GCP infrastructure, lower specs, deletion protection OFF. Used for developing using GCP resource APIs.
- **azuretest**: Azure validation environment for AKS, private PostgreSQL, private Key Vault, Azure DNS, Azure Front Door, ACR, Blob/static website storage, and Azure workflow identities. Some GCP-only features such as access canaries and critical alerting are intentionally out of scope for now.
- **staging**: (future) Full infrastructure, production specs, deletion protection ON  
- **prod**: (future) Full infrastructure, production specs, deletion protection ON
- **GKE deletion protection**: OFF for dev (`is_dev = true`), ON for staging/prod (`!var.is_dev`).
- **Azure deletion protection**: Development resources may allow cleanup, but production-like Azure database resources should use deletion protection/locks where available.

## Security Considerations
- All inter-service communication uses private IPs
- Cloud SQL accessible only through VPC
- Frontend bucket has uniform access control (no per-object ACLs)
