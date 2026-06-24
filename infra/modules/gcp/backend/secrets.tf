# Create secrets for backend secret environment variables
module "backend_secrets" {
  for_each = var.backend_secret_env_vars
  source   = "../secret"

  gcp_project_id         = var.gcp_project_id
  environment            = var.environment
  secret_name            = each.key
  initial_secret_value   = each.value
  secret_prefix          = "backend"
  service_account_emails = [google_service_account.default.email, var.external_secrets_service_account_email]

  labels = {
    purpose     = "backend-env-var"
    service     = "backend"
    environment = var.environment
  }

  depends_on = [google_service_account.default]
}

# Create the DATABASE_URL secret
module "database_url_secret" {
  source = "../secret"

  gcp_project_id         = var.gcp_project_id
  environment            = var.environment
  secret_name            = "DATABASE_URL"
  initial_secret_value   = "postgresql://${var.db_user_name}:${var.db_user_password}@localhost:5432/${var.db_name}?host=/cloudsql/${var.database_connection_name}"
  secret_prefix          = "backend"
  service_account_emails = [google_service_account.default.email, var.external_secrets_service_account_email]
  ignore_secret_changes  = false # Allow updates when database details change

  labels = {
    purpose     = "database-connection"
    service     = "backend"
    environment = var.environment
  }

  depends_on = [google_service_account.default]
}

# Create a map of Secret Manager references for the backend runtime.
locals {
  backend_secret_refs = merge(
    {
      DATABASE_URL = module.database_url_secret.secret_ref
    },
    {
      for key, secret_module in module.backend_secrets :
      key => secret_module.secret_ref
    }
  )

}
