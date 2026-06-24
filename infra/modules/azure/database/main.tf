locals {
  database_name = "app"
  database_user = "appadmin"
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }
}

resource "random_password" "database_password" {
  length           = 32
  override_special = "-._~"
  special          = true
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.name_prefix}-postgres-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_postgresql_flexible_server" "default" {
  name                          = substr("${var.name_prefix}-db-${var.suffix}", 0, 63)
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "17"
  delegated_subnet_id           = var.postgres_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = local.database_user
  administrator_password        = random_password.database_password.result
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = var.is_dev ? 7 : 14
  tags                          = local.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres,
  ]

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      zone,
    ]
  }
}

resource "azurerm_management_lock" "postgres_server" {
  count = var.is_dev ? 0 : 1

  name       = "${var.name_prefix}-postgres-deletion-lock"
  scope      = azurerm_postgresql_flexible_server.default.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of the PostgreSQL Flexible Server."
}

resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = local.database_name
  server_id = azurerm_postgresql_flexible_server.default.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}
