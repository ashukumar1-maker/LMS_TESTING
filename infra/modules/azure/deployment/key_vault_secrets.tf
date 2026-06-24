module "backend_secrets" {
  for_each = var.backend_secret_env_vars
  source   = "../secret"

  key_vault_id         = azurerm_key_vault.default.id
  project_id           = var.project_id
  environment          = var.environment
  secret_name          = each.key
  initial_secret_value = each.value

  tags = {
    purpose = "backend-env-var"
    service = "backend"
  }

  depends_on = [null_resource.current_key_vault_secret_writer_access]
}

module "database_url_secret" {
  source = "../secret"

  key_vault_id          = azurerm_key_vault.default.id
  project_id            = var.project_id
  environment           = var.environment
  secret_name           = local.database_url_secret_name
  initial_secret_value  = module.database.database_url
  ignore_secret_changes = false

  tags = {
    purpose = "database-connection"
    service = "backend"
  }

  depends_on = [null_resource.current_key_vault_secret_writer_access]
}

module "database_password_secret" {
  source = "../secret"

  key_vault_id          = azurerm_key_vault.default.id
  project_id            = var.project_id
  environment           = var.environment
  secret_name           = local.database_password_secret_name
  initial_secret_value  = module.database.database_password
  ignore_secret_changes = false

  tags = {
    purpose = "database-password"
    service = "database"
  }

  depends_on = [null_resource.current_key_vault_secret_writer_access]
}

module "sentry_auth_token_secret" {
  source = "../secret"

  key_vault_id         = azurerm_key_vault.default.id
  project_id           = var.project_id
  environment          = var.environment
  secret_name          = local.sentry_auth_token_secret_name
  initial_secret_value = "PLACEHOLDER_REPLACE_WITH_REAL_TOKEN"

  tags = {
    purpose = "sentry-auth-token"
    service = "frontend"
  }

  depends_on = [null_resource.current_key_vault_secret_writer_access]
}
