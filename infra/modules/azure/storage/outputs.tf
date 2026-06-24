output "storage_account_id" {
  description = "Azure Storage account ID."
  value       = var.storage_account_id
}

output "storage_account_name" {
  description = "Azure Storage account name."
  value       = var.storage_account_name
}

output "backend_container_name" {
  description = "Backend blob container name."
  value       = azurerm_storage_container.backend.name
}
