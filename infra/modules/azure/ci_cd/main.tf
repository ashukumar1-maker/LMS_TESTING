locals {
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }

  kubernetes_service_accounts = {
    workflow_orchestrator = "${var.environment}-workflow-orchestrator"
    terraform_apply       = "${var.environment}-terraform-apply"
    source_inspector      = "${var.environment}-source-inspector"
    backend_builder       = "${var.environment}-backend-builder"
    backend_rollout       = "${var.environment}-backend-rollout"
    frontend_deployer     = "${var.environment}-frontend-deployer"
    cdn_invalidator       = "${var.environment}-cdn-invalidator"
  }

  workload_identity_subjects = {
    terraform_apply   = "system:serviceaccount:${var.workflow_namespace}:${local.kubernetes_service_accounts.terraform_apply}"
    source_inspector  = "system:serviceaccount:${var.workflow_namespace}:${local.kubernetes_service_accounts.source_inspector}"
    backend_builder   = "system:serviceaccount:${var.workflow_namespace}:${local.kubernetes_service_accounts.backend_builder}"
    frontend_deployer = "system:serviceaccount:${var.workflow_namespace}:${local.kubernetes_service_accounts.frontend_deployer}"
    cdn_invalidator   = "system:serviceaccount:${var.workflow_namespace}:${local.kubernetes_service_accounts.cdn_invalidator}"
  }
}

resource "azurerm_user_assigned_identity" "task" {
  for_each = local.workload_identity_subjects

  name                = "${var.name_prefix}-${replace(each.key, "_", "-")}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "task" {
  for_each = local.workload_identity_subjects

  name                      = "${replace(each.key, "_", "-")}-kubernetes"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.task[each.key].id
  subject                   = each.value
}

resource "azurerm_role_assignment" "terraform_apply_resource_group_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.task["terraform_apply"].principal_id
}

resource "azurerm_role_assignment" "terraform_apply_resource_group_rbac_administrator" {
  scope                = var.resource_group_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.task["terraform_apply"].principal_id
}

resource "azurerm_role_assignment" "terraform_apply_storage_blob_data_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.task["terraform_apply"].principal_id
}

resource "azurerm_role_assignment" "backend_builder_acr_push" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.task["backend_builder"].principal_id
}

resource "azurerm_role_assignment" "backend_builder_acr_tasks_contributor" {
  scope                = var.container_registry_id
  role_definition_name = "Container Registry Tasks Contributor"
  principal_id         = azurerm_user_assigned_identity.task["backend_builder"].principal_id
}

resource "azurerm_role_assignment" "source_inspector_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.task["source_inspector"].principal_id
}

resource "azurerm_role_assignment" "frontend_deployer_storage_blob_data_contributor" {
  scope                = var.frontend_static_website_container_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.task["frontend_deployer"].principal_id
}

resource "azurerm_role_assignment" "frontend_deployer_sentry_auth_token_secrets_user" {
  scope                = var.sentry_auth_token_secret_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.task["frontend_deployer"].principal_id
}

resource "azurerm_role_assignment" "cdn_invalidator_cdn_profile_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "CDN Profile Contributor"
  principal_id         = azurerm_user_assigned_identity.task["cdn_invalidator"].principal_id
}
