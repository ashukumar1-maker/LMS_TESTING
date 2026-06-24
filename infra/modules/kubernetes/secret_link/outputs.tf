output "secret_store_name" {
  description = "Kubernetes SecretStore name."
  value       = local.secret_store_name
}

output "external_secret_name" {
  description = "Kubernetes ExternalSecret name."
  value       = var.external_secret_name
}

output "target_secret_name" {
  description = "Kubernetes Secret name created by External Secrets."
  value       = var.target_secret_name
}
