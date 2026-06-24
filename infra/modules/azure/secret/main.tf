locals {
  normalized_secret_name = lower(replace(var.secret_name, "_", "-"))
  secret_name            = var.secret_prefix != "" ? "${var.secret_prefix}-${local.normalized_secret_name}" : local.normalized_secret_name

  default_tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }

  tags = merge(local.default_tags, var.tags)

  body = {
    properties = {
      attributes = {
        enabled = true
      }
    }
  }

  sensitive_body = {
    properties = {
      value = var.initial_secret_value
    }
  }

  sensitive_body_version = {
    "properties.value" = nonsensitive(sha256(var.initial_secret_value))
  }
}

resource "azapi_resource" "secret_static" {
  count = var.ignore_secret_changes ? 1 : 0

  type      = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  name      = local.secret_name
  parent_id = var.key_vault_id
  tags      = local.tags

  body                   = local.body
  sensitive_body         = local.sensitive_body
  sensitive_body_version = local.sensitive_body_version

  lifecycle {
    ignore_changes = [
      sensitive_body,
      sensitive_body_version,
      tags,
    ]
  }
}

resource "azapi_resource" "secret_dynamic" {
  count = var.ignore_secret_changes ? 0 : 1

  type      = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  name      = local.secret_name
  parent_id = var.key_vault_id
  tags      = local.tags

  body                   = local.body
  sensitive_body         = local.sensitive_body
  sensitive_body_version = local.sensitive_body_version

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
