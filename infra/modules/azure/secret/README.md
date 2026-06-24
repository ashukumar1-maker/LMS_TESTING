# Azure Secret Module

Creates a single Azure Key Vault secret.

## Responsibilities

- Normalizes secret names for Azure Key Vault by lowercasing and replacing
  underscores with hyphens.
- Writes the secret through the Azure management plane
  `Microsoft.KeyVault/vaults/secrets` child resource.
- Supports manually rotated static secrets by ignoring value changes by default.
- Supports Terraform-computed secrets by setting `ignore_secret_changes = false`.

## Key Inputs

- `key_vault_id`: Key Vault that will contain the secret.
- `secret_name`: Logical secret name. For example, `DATABASE_URL` becomes
  `database-url`.
- `initial_secret_value`: Secret value to write. This is sensitive.
- `secret_prefix`: Optional prefix for namespacing secret names.
- `ignore_secret_changes`: Defaults to `true` for manually rotated values.

## Outputs

- `secret_id`: Full Azure resource ID for the Key Vault secret.
- `secret_name`: Key Vault secret name.
- `secret_ref`: External Secrets reference name. For Azure this is the Key Vault
  secret name.

## Notes

This module intentionally uses AzAPI instead of `azurerm_key_vault_secret`.
AzureTest Key Vaults are private-only, and the ARM child resource path lets
Terraform seed secrets without needing data-plane network access to the private
vault endpoint. Microsoft documents `properties.value` on
`Microsoft.KeyVault/vaults/secrets`; the value is write-only and is not returned
by Azure.
