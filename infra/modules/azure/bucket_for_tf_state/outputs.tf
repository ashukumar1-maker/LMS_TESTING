output "container_name" {
  description = "Terraform state blob container name."
  value       = azurerm_storage_container.terraform_state.name
}
