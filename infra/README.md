# Infrastructure

This directory contains Terraform configurations for deploying infrastructure. Environment roots keep a common `module "deployment"` name while sourcing the provider-specific deployment module for the target cloud directly.

## Quick Start

1. **[Setup](./docs/setup.md)** - Install required software, authenticate, and configure Argo workflow deployments
2. **[Provision Infrastructure](./docs/provisioning.md)** - Deploy with Terraform
3. **[Configure DNS](./docs/dns-setup.md)** - Set up domain and DNSSEC
4. **[Multi-Cloud Modules](./docs/multi-cloud-modules.md)** - Understand provider-specific Terraform module organization

## Documentation

- **[Setup Guide](./docs/setup.md)** - Required software, authentication, Argo workflow submission, and environment variables
- **[Creating New Environments](./docs/new-environment.md)** - How to create staging, prod, or other environments
- **[Provisioning Guide](./docs/provisioning.md)** - Terraform commands and troubleshooting
- **[DNS Setup Guide](./docs/dns-setup.md)** - Complete DNS and DNSSEC configuration
- **[Private GKE](./docs/gke.md)** - GKE cluster, Connect Gateway, and two-phase infra apply flow
- **[CD Workflow Operations](./docs/cd-workflow.md)** - Argo workflow updates, cluster replacement guardrails, and chart/CRD changes
- **[Multi-Cloud Modules](./docs/multi-cloud-modules.md)** - GCP and future Azure module organization
- **[Logging Policy](./docs/logging-policy.md)** - Log categories, retention windows, and compliance rationale
- **[Backend CD Tasks](./docs/backend-cd-tasks.md)** - Registering and running deployment-time backend tasks

## Directory Structure

```
infra/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment 
│   └── prod/             # Production environment
├── modules/              # Provider-specific Terraform modules
│   ├── kubernetes/       # Kubernetes CRDs, runtime config, and CD workflow
│   ├── azure/           # Azure module implementations
│   └── gcp/             # GCP modules, including GKE and CD workflow steps
├── scripts/              # Python scripts for state management
│   ├── pullstate.py     # Download state from remote storage
│   ├── pushstate.py     # Upload state to remote storage
│   └── common/          # Shared Python package for the above scripts
├── docs/                # Detailed documentation
└── AGENTS.md           # Infrastructure operations guide
```

## State Management

Terraform state files are backed up to remote object storage within each
environment's cloud account. GCP environments use a Google Cloud Storage (GCS)
bucket; Azure environments use the `terraform-state` blob container in the
environment's storage account. This ensures:
- State files are safely stored and backed up
- Multiple team members can collaborate on infrastructure
- State history is preserved for disaster recovery

The sync scripts pick the backend by inspecting the environment's tfvars file:
an `azure_subscription_id` selects Azure and a `gcp_project_id` selects GCP
(the default). GCP uses `gcloud` and Azure uses `az`, so make sure the matching
CLI is installed and authenticated (`gcloud auth login` or `az login`).

### State Sync Scripts

The `scripts/` directory contains Python utilities to manage Terraform state files:

#### Pulling State (Download from Cloud)

Use `pullstate.py` when you need to:
- Start working on an existing environment
- Sync with the latest infrastructure changes
- Recover from local state corruption

```bash
# From within an environment directory
cd environments/dev
uv run ../../scripts/pullstate.py

# From anywhere, specify the environment
uv run ./scripts/pullstate.py -e dev

# Skip confirmation prompts
uv run ./scripts/pullstate.py -e dev -f

# If the tfvars file doesn't exist, provide IDs manually
uv run ./scripts/pullstate.py -e dev -p fullstack-template-1 -g fullstack-template-1-dev

# Azure environment
uv run ./scripts/pullstate.py -e azuretest
```

#### Pushing State (Upload to Cloud)

Use `pushstate.py` when you need to:
- Back up state right after infrastructure changes
- Share changes with team members
- Ensure state is safely stored

```bash
# From within an environment directory
cd environments/dev
uv run ../../scripts/pushstate.py

# From anywhere, specify the environment
uv run ./scripts/pushstate.py -e dev

# Skip confirmation prompts
uv run ./scripts/pushstate.py -e dev -f

# If the tfvars file doesn't exist, provide IDs manually
uv run ./scripts/pushstate.py -e dev -p fullstack-template-1 -g fullstack-template-1-dev

# Azure environment
uv run ./scripts/pushstate.py -e azuretest
```

> **Azure note**: state lives in the `terraform-state` blob container of the
> environment's storage account. Because the account name carries a random
> suffix, the scripts discover it from the deterministic resource group
> (`<project>-<environment>-rg`). The infrastructure must be provisioned (the
> storage account must exist) before state can be pushed or pulled. Blob
> operations use the storage account access key, retrieved via the control
> plane, so an operator with the Contributor or Owner role can sync state
> without a separate `Storage Blob Data` data-plane role assignment.

### Safety Features

Both scripts include multiple safety checks:

1. **Replacement Warnings** - Shows which files will be replaced
2. **Timestamp Validation** - Warns if you're overwriting newer files
3. **Confirmation Prompts** - Requires explicit confirmation
4. **Force Flag (`-f`)** - Skip prompts when you're confident

### What Gets Synced

- `terraform.tfstate` - Current infrastructure state, pulled and pushed
- `terraform.auto.tfvars` - Environment configuration, pulled and pushed
- `terraform.tfvars` - Environment configuration for environments that use this filename (e.g. Azure), pulled and pushed
- `terraform.tfstate.backup` - Previous state backup, pushed and refreshed in the remote store
- `terraform.tfstate.*.backup` - Numbered backup files, auto-discovered by `pushstate.py` and pushed only if not already in the remote store

The `.tfstate-sync.yaml` config only supports explicit files; glob patterns are not supported. Backup files are never downloaded by `pullstate.py`, even when they are listed in the sync configuration or auto-discovered by push.

## Typical Workflows

### Starting on a New Machine

```bash
# 1. Clone the repository
git clone <repository-url>
cd <repository>/infra/environments/dev

# 2. Pull existing state
uv run ../../scripts/pullstate.py

# 3. Initialize Terraform
terraform init

# 4. Verify current infrastructure
terraform plan
```

### Making Infrastructure Changes

```bash
# 1. Pull latest state
cd infra/environments/dev
uv run ../../scripts/pullstate.py

# 2. Make your changes
terraform plan
terraform apply

# 3. Push updated state
uv run ../../scripts/pushstate.py

# 4. Commit code changes
git add .
git commit -m "Infrastructure update"
git push
```

## Environment Variables

The infrastructure supports three types of environment variables:
- **Backend Environment Variables** - Non-sensitive config values
- **Backend Secret Environment Variables** - Sensitive values in Secret Manager
- **Frontend Environment Variables** - Build-time variables (must start with VITE_)

For detailed instructions on adding and managing environment variables, see the **[Environment Variables Guide](./docs/environment-variables.md)**.

## Best Practices for Infrastructure Changes

1. **Always pull before starting** - Ensures you have the latest state
2. **Push immediately after apply** - Backs up your changes
3. **Never commit state files** - They're in `.gitignore` for security
4. **Review timestamp warnings** - Understand why files differ before proceeding
5. **Never use the force flag** - The flag is there for use in automated workflows

## Troubleshooting

### Authentication Issues

```bash
# Login to Google Cloud (GCP environments)
gcloud auth login

# Login to Azure (Azure environments)
az login
```

### Permission Errors

For GCP environments, ensure your account has:
- Storage Object Viewer (for pulling)
- Storage Object Creator (for pushing)

For Azure environments, blob operations use the storage account access key
retrieved via the control plane, so an operator with the Contributor or Owner
role on the storage account can sync state without a separate `Storage Blob
Data` data-plane role assignment.

### State Lock Conflicts

If Terraform reports a locked state:
1. Wait briefly - another operation may be running
2. Check with team members
3. If certain no one is using it: `terraform force-unlock <lock-id>`

## Key Concepts

- **Environments**: Each environment (dev, staging, prod) has its own directory with isolated state
- **Modules**: Reusable infrastructure components shared across environments
- **State Storage**: Each environment stores its state in its own cloud account. GCP environments use a per-environment GCS bucket; Azure environments use the `terraform-state` blob container in the environment's storage account
- **State Isolation**: Never share state files between environments
- **DNS**: Subdomain delegation with DNSSEC for secure domain management

For detailed information on any topic, see the documentation links above.
