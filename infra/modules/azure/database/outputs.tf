output "database_name" {
  description = "Application database name."
  value       = azurerm_postgresql_flexible_server_database.default.name
}

output "database_fqdn" {
  description = "Azure PostgreSQL Flexible Server FQDN."
  value       = azurerm_postgresql_flexible_server.default.fqdn
}

output "database_url" {
  description = "Application PostgreSQL connection string."
  value       = "postgresql://${local.database_user}:${random_password.database_password.result}@${azurerm_postgresql_flexible_server.default.fqdn}:5432/${azurerm_postgresql_flexible_server_database.default.name}?sslmode=require"
  sensitive   = true
}

output "database_password" {
  description = "Generated PostgreSQL administrator password."
  value       = random_password.database_password.result
  sensitive   = true
}
