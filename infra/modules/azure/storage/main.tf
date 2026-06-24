resource "azurerm_storage_container" "backend" {
  name                  = "backend"
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}
