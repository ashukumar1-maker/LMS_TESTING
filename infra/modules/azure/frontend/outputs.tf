output "endpoint_id" {
  description = "Azure Front Door endpoint resource ID."
  value       = azurerm_cdn_frontdoor_endpoint.frontend.id
}

output "endpoint_name" {
  description = "Azure Front Door endpoint name."
  value       = azurerm_cdn_frontdoor_endpoint.frontend.name
}

output "endpoint_host_name" {
  description = "Azure Front Door default endpoint host name."
  value       = azurerm_cdn_frontdoor_endpoint.frontend.host_name
}

output "frontend_url" {
  description = "HTTPS URL for the frontend custom domain."
  value       = "https://${var.domain_name}"
}

output "frontend_static_website_container_id" {
  description = "Azure Blob container ID for static website frontend assets."
  value       = "${azurerm_storage_account_static_website.frontend.storage_account_id}/blobServices/default/containers/$web"
}

output "profile_name" {
  description = "Azure Front Door profile name used for cache purge commands."
  value       = azurerm_cdn_frontdoor_profile.frontend.name
}

output "custom_domain_validation_token" {
  description = "DNS TXT validation token for the Azure Front Door custom domain."
  value       = azurerm_cdn_frontdoor_custom_domain.frontend.validation_token
}
