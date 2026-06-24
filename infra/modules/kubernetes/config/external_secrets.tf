module "secret_link" {
  source = "../secret_link"

  cloud                                 = var.cloud
  gcp_project_id                        = var.gcp_project_id
  azure_key_vault_url                   = var.azure_key_vault_url
  azure_tenant_id                       = var.azure_tenant_id
  namespace                             = local.backend_namespace
  external_secrets_namespace            = var.external_secrets_namespace
  external_secrets_service_account_name = var.external_secrets_service_account_name
  secret_store_labels                   = local.secret_store_labels
  labels                                = local.labels
  target_secret_name                    = local.backend_secret_name
  secret_names                          = local.backend_secret_names
}
