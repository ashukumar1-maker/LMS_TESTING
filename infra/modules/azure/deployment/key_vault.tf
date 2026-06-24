resource "azurerm_key_vault" "default" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.default.location
  resource_group_name           = azurerm_resource_group.default.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  purge_protection_enabled      = !var.is_dev
  soft_delete_retention_days    = 7
  tags                          = local.tags
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.default.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "${local.name_prefix}-kv-link"
  resource_group_name   = azurerm_resource_group.default.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = module.network.virtual_network_id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.name_prefix}-kv-pe"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = module.network.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.name_prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.default.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "key-vault"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.key_vault,
  ]
}
