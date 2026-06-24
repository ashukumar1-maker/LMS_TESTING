resource "azurerm_storage_container" "terraform_state" {
  name                  = "terraform-state"
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}
