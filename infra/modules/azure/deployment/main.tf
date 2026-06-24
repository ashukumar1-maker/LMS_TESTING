data "azurerm_client_config" "current" {}

resource "random_string" "resource_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  safe_project     = replace(lower(var.project_id), "/[^a-z0-9-]/", "-")
  safe_environment = replace(lower(var.environment), "/[^a-z0-9-]/", "-")
  name_prefix      = substr("${local.safe_project}-${local.safe_environment}", 0, 40)
  compact_name     = substr(replace(lower("${var.project_id}${var.environment}"), "/[^a-z0-9]/", ""), 0, 14)
  suffix           = random_string.resource_suffix.result

  storage_account_name = substr("${local.compact_name}${local.suffix}", 0, 24)
  key_vault_name       = substr("${local.compact_name}kv${local.suffix}", 0, 24)
  acr_name             = substr("${local.compact_name}acr${local.suffix}", 0, 50)
  aks_dns_prefix       = substr("${local.compact_name}-${local.suffix}", 0, 54)
  aks_node_rg_name     = substr("${local.compact_name}-${local.suffix}-aks-nodes", 0, 80)

  backend_namespace                     = "backend"
  backend_service_account_name          = "backend"
  external_secrets_namespace            = "external-secrets"
  external_secrets_service_account_name = "external-secrets"
  workflow_namespace                    = "argo"
  workflow_template_name                = "deploy-fullstack-template"
  database_url_secret_name              = "database-url"
  database_password_secret_name         = "database-password"
  sentry_auth_token_secret_name         = "${var.environment}-sentry-auth-token"

  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "default" {
  name     = "${local.name_prefix}-rg"
  location = var.region

  tags = local.tags
}

resource "azurerm_storage_account" "default" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.default.name
  location                        = azurerm_resource_group.default.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

module "network" {
  source = "../network"

  resource_group_name          = azurerm_resource_group.default.name
  location                     = azurerm_resource_group.default.location
  project_id                   = var.project_id
  environment                  = var.environment
  name_prefix                  = local.name_prefix
  vnet_address_space           = var.vnet_address_space
  aks_subnet_cidr              = var.aks_subnet_cidr
  api_server_subnet_cidr       = var.aks_api_server_subnet_cidr
  postgres_subnet_cidr         = var.postgres_subnet_cidr
  private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr
}

resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "${local.name_prefix}-aks-control-plane"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "aks_control_plane_node_subnet_network_contributor" {
  scope                = module.network.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

resource "azurerm_role_assignment" "aks_control_plane_api_server_subnet_network_contributor" {
  scope                = module.network.api_server_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

resource "azurerm_role_assignment" "aks_control_plane_resource_group_network_contributor" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

module "aks" {
  source = "../aks"

  resource_group_name        = azurerm_resource_group.default.name
  location                   = azurerm_resource_group.default.location
  project_id                 = var.project_id
  environment                = var.environment
  name_prefix                = local.name_prefix
  dns_prefix                 = local.aks_dns_prefix
  node_resource_group_name   = local.aks_node_rg_name
  aks_subnet_id              = module.network.aks_subnet_id
  api_server_subnet_id       = module.network.api_server_subnet_id
  control_plane_identity_id  = azurerm_user_assigned_identity.aks_control_plane.id
  public_cluster_enabled     = var.aks_public_cluster_enabled
  node_count                 = var.aks_node_count
  min_node_count             = var.aks_min_node_count
  max_node_count             = var.aks_max_node_count
  node_vm_size               = var.aks_node_vm_size
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  depends_on = [
    azurerm_role_assignment.aks_control_plane_node_subnet_network_contributor,
    azurerm_role_assignment.aks_control_plane_api_server_subnet_network_contributor,
    azurerm_role_assignment.aks_control_plane_resource_group_network_contributor,
  ]
}

module "database" {
  source = "../database"

  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  project_id          = var.project_id
  environment         = var.environment
  name_prefix         = local.name_prefix
  suffix              = local.suffix
  virtual_network_id  = module.network.virtual_network_id
  postgres_subnet_id  = module.network.postgres_subnet_id
  is_dev              = var.is_dev
  sku_name            = var.postgres_sku_name
  storage_mb          = var.postgres_storage_mb
}

module "storage" {
  source = "../storage"

  project_id           = var.project_id
  environment          = var.environment
  storage_account_id   = azurerm_storage_account.default.id
  storage_account_name = azurerm_storage_account.default.name
}

module "frontend" {
  source = "../frontend"

  resource_group_name  = azurerm_resource_group.default.name
  project_id           = var.project_id
  environment          = var.environment
  name_prefix          = local.name_prefix
  suffix               = local.suffix
  domain_name          = var.domain_name
  storage_account_id   = azurerm_storage_account.default.id
  storage_account_name = azurerm_storage_account.default.name
}

module "bucket_for_tf_state" {
  source = "../bucket_for_tf_state"

  storage_account_id = azurerm_storage_account.default.id
}

module "backend" {
  source = "../backend"

  resource_group_name                   = azurerm_resource_group.default.name
  location                              = azurerm_resource_group.default.location
  project_id                            = var.project_id
  environment                           = var.environment
  name_prefix                           = local.name_prefix
  acr_name                              = local.acr_name
  oidc_issuer_url                       = module.aks.oidc_issuer_url
  backend_namespace                     = local.backend_namespace
  backend_service_account_name          = local.backend_service_account_name
  external_secrets_namespace            = local.external_secrets_namespace
  external_secrets_service_account_name = local.external_secrets_service_account_name
  storage_account_id                    = azurerm_storage_account.default.id
  storage_account_name                  = azurerm_storage_account.default.name
  backend_container_name                = module.storage.backend_container_name
  key_vault_id                          = azurerm_key_vault.default.id
  azure_subscription_id                 = var.azure_subscription_id
  auth_service_backend_url              = var.auth_service_backend_url
  backend_env_vars                      = var.backend_env_vars
}

module "ci_cd" {
  source = "../ci_cd"

  resource_group_name                  = azurerm_resource_group.default.name
  location                             = azurerm_resource_group.default.location
  project_id                           = var.project_id
  environment                          = var.environment
  name_prefix                          = local.name_prefix
  oidc_issuer_url                      = module.aks.oidc_issuer_url
  workflow_namespace                   = local.workflow_namespace
  resource_group_id                    = azurerm_resource_group.default.id
  storage_account_id                   = azurerm_storage_account.default.id
  frontend_static_website_container_id = module.frontend.frontend_static_website_container_id
  container_registry_id                = module.backend.artifact_registry_repository_id
  sentry_auth_token_secret_id          = module.sentry_auth_token_secret.secret_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.backend.artifact_registry_repository_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

module "dns" {
  source = "../dns"

  resource_group_name                     = azurerm_resource_group.default.name
  project_id                              = var.project_id
  environment                             = var.environment
  domain_name                             = var.domain_name
  backend_ip_address                      = module.network.backend_public_ip_address
  frontend_endpoint_id                    = module.frontend.endpoint_id
  frontend_custom_domain_validation_token = module.frontend.custom_domain_validation_token

  providers = {
    azapi = azapi
  }

  depends_on = [
    module.frontend,
  ]
}
