# Secret Module

This module creates a single Google Secret Manager secret and manages access permissions for specified service accounts.

## Features

- Creates a Google Secret Manager secret with automatic replication
- Sets an initial secret value that can be manually rotated later
- Grants secret accessor permissions to specified service accounts
- Supports custom labels and naming prefixes
- Protects against accidental secret value updates via Terraform (configurable)

## Usage

```hcl
module "api_key_secret" {
  source = "./modules/gcp/secret"
  
  gcp_project_id         = var.gcp_project_id
  environment            = var.environment
  secret_name            = "API_KEY"
  initial_secret_value   = var.api_key_value
  secret_prefix          = "backend"
  service_account_emails = [
    "backend-service@project.iam.gserviceaccount.com",
    "worker-service@project.iam.gserviceaccount.com"
  ]
  
  labels = {
    purpose = "external-api-auth"
  }
}

# For dynamic secrets that should update when values change
module "database_url_secret" {
  source = "./modules/gcp/secret"
  
  gcp_project_id         = var.gcp_project_id
  environment            = var.environment
  secret_name            = "DATABASE_URL"
  initial_secret_value   = "postgresql://${var.db_user}:${var.db_pass}@localhost/db"
  ignore_secret_changes  = false  # Allow updates when DB credentials change
  secret_prefix          = "backend"
  service_account_emails = ["backend-service@project.iam.gserviceaccount.com"]
}
```

## Variables

- `gcp_project_id` (required): The GCP project ID where the secret will be created
- `environment` (required): The environment name (e.g., dev, staging, prod)
- `secret_name` (required): The name of the secret (will be sanitized for the secret ID)
- `initial_secret_value` (required): The initial value of the secret
- `service_account_emails` (optional): List of service account emails that should have read access
- `secret_prefix` (optional): Prefix for the secret ID (e.g., 'backend', 'api')
- `labels` (optional): Additional labels to apply to the secret
- `ignore_secret_changes` (optional): Whether to ignore changes to secret data after initial creation (default: true)

## Outputs

- `secret_id`: The ID of the created secret
- `secret_name`: The full resource name of the secret
- `secret_ref`: Reference to the latest version for use in Cloud Run environment variables
- `secret_version_name`: The full resource name of the secret version

## Secret Naming

The module automatically generates a secret ID based on:
- Environment name
- Optional prefix
- Secret name (with underscores replaced by hyphens)

Example: `dev-backend-api-key`

## Security Notes

- By default, the module ignores changes to `secret_data` after initial creation to prevent accidental updates
- Set `ignore_secret_changes = false` for secrets that should update when their computed values change (e.g., DATABASE_URL)
- Secrets can be manually rotated using the Google Cloud Console or gcloud CLI
- Service accounts are granted `roles/secretmanager.secretAccessor` role only
