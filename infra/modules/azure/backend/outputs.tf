output "artifact_registry_repository_id" {
  description = "Azure Container Registry ID."
  value       = azurerm_container_registry.default.id
}

output "container_registry_login_server" {
  description = "Azure Container Registry login server."
  value       = azurerm_container_registry.default.login_server
}

output "backend_runtime_env_vars" {
  description = "Non-secret backend runtime environment variables."
  value       = local.backend_runtime_env_vars
}

output "default_container_image_uri" {
  description = "Default backend image URI used before the first deployment build."
  value       = "${azurerm_container_registry.default.login_server}/${var.default_container_name}:${var.default_container_tag}"
}

output "backend_identity_client_id" {
  description = "Backend workload identity client ID."
  value       = azurerm_user_assigned_identity.workload["backend"].client_id
}

output "external_secrets_identity_client_id" {
  description = "External Secrets workload identity client ID."
  value       = azurerm_user_assigned_identity.workload["external_secrets"].client_id
}
