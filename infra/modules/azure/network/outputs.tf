output "virtual_network_id" {
  description = "Azure VNet ID."
  value       = azurerm_virtual_network.default.id
}

output "virtual_network_name" {
  description = "Azure VNet name."
  value       = azurerm_virtual_network.default.name
}

output "aks_subnet_id" {
  description = "AKS subnet ID."
  value       = azurerm_subnet.aks.id
}

output "api_server_subnet_id" {
  description = "AKS API Server VNet Integration subnet ID."
  value       = azurerm_subnet.api_server.id
}

output "postgres_subnet_id" {
  description = "PostgreSQL delegated subnet ID."
  value       = azurerm_subnet.postgres.id
}

output "private_endpoint_subnet_id" {
  description = "Private Endpoint subnet ID."
  value       = azurerm_subnet.private_endpoints.id
}

output "backend_public_ip_name" {
  description = "Backend public IP resource name."
  value       = azurerm_public_ip.backend.name
}

output "backend_public_ip_address" {
  description = "Backend public IP address."
  value       = azurerm_public_ip.backend.ip_address
}
