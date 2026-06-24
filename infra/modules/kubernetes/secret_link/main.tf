terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

locals {
  cloud = lower(var.cloud)
  secret_store_name = coalesce(
    var.secret_store_name,
    local.cloud == "gcp" ? "google-secret-manager" : "azure-key-vault",
  )
  secret_store_labels = coalesce(var.secret_store_labels, var.labels)
}

module "gcp" {
  count = local.cloud == "gcp" ? 1 : 0

  source = "../../gcp/kubernetes_secret_link"

  gcp_project_id       = coalesce(var.gcp_project_id, "")
  namespace            = var.namespace
  labels               = var.labels
  secret_store_labels  = local.secret_store_labels
  secret_store_name    = local.secret_store_name
  external_secret_name = var.external_secret_name
  target_secret_name   = var.target_secret_name
  secret_names         = var.secret_names
  refresh_interval     = var.refresh_interval
}

module "azure" {
  count = local.cloud == "azure" ? 1 : 0

  source = "../../azure/kubernetes_secret_link"

  key_vault_url                         = coalesce(var.azure_key_vault_url, "")
  tenant_id                             = coalesce(var.azure_tenant_id, "")
  namespace                             = var.namespace
  external_secrets_namespace            = coalesce(var.external_secrets_namespace, "")
  external_secrets_service_account_name = coalesce(var.external_secrets_service_account_name, "")
  labels                                = var.labels
  secret_store_labels                   = local.secret_store_labels
  secret_store_name                     = local.secret_store_name
  external_secret_name                  = var.external_secret_name
  target_secret_name                    = var.target_secret_name
  secret_names                          = var.secret_names
  refresh_interval                      = var.refresh_interval
}
