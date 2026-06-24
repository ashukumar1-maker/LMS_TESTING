locals {
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }

  workload_identity_subjects = {
    backend          = "system:serviceaccount:${var.backend_namespace}:${var.backend_service_account_name}"
    external_secrets = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account_name}"
  }

  backend_runtime_env_vars = merge(
    {
      ENVIRONMENT                  = var.environment
      PROJECT_ID                   = var.project_id
      GOOGLE_CLOUD_PROJECT         = ""
      BACKEND_BUCKET_MOUNT_PATH    = "/mnt/blob"
      AUTH_SERVICE_BACKEND_URL     = var.auth_service_backend_url
      AZURE_STORAGE_ACCOUNT_NAME   = var.storage_account_name
      AZURE_STORAGE_CONTAINER_NAME = var.backend_container_name
      AZURE_SUBSCRIPTION_ID        = var.azure_subscription_id
    },
    var.backend_env_vars
  )
}

resource "azurerm_container_registry" "default" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  for_each = local.workload_identity_subjects

  name                = "${var.name_prefix}-${replace(each.key, "_", "-")}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "workload" {
  for_each = local.workload_identity_subjects

  name                      = "${replace(each.key, "_", "-")}-kubernetes"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.workload[each.key].id
  subject                   = each.value
}

resource "azurerm_role_assignment" "backend_storage_blob_data_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload["backend"].principal_id
}

resource "azurerm_role_assignment" "external_secrets_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload["external_secrets"].principal_id
}
