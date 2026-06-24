# Provisioning Infrastructure

## Prerequisites

**Important**: The GCP project must already exist before running Terraform. Project provisioning is not handled by Terraform.

## Initial Provisioning

Before running Terraform, ensure:
1. The GCP project exists (e.g., `int-fullstacktemplate-1-dev` for dev environment)
2. You have the necessary permissions on the project
3. The billing account is linked to the project
4. **The Cloud Resource Manager API is enabled** (required for Terraform to interact with the project):
   ```bash
   gcloud services enable cloudresourcemanager.googleapis.com --project=PROJECT_ID
   ```
   All other APIs will be enabled automatically by Terraform

If the infrastructure has already been provisioned by someone else, make sure you have the tfstate files in the correct environment directory.

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```