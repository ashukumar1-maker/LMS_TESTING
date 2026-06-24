locals {
  secret = var.ignore_secret_changes ? azapi_resource.secret_static[0] : azapi_resource.secret_dynamic[0]
}

output "secret_id" {
  description = "Azure Key Vault secret resource ID."
  value       = local.secret.id
}

output "secret_name" {
  description = "Azure Key Vault secret name."
  value       = local.secret.name
}

output "secret_ref" {
  description = "Reference name used by Kubernetes External Secrets."
  value       = local.secret.name
}
