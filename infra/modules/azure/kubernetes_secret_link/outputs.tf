output "secret_store_name" {
  description = "Kubernetes ClusterSecretStore name."
  value       = kubernetes_manifest.secret_store.manifest.metadata.name
}

output "external_secret_name" {
  description = "Kubernetes ExternalSecret name."
  value       = kubernetes_manifest.external_secret.manifest.metadata.name
}

output "target_secret_name" {
  description = "Kubernetes Secret name created by External Secrets."
  value       = var.target_secret_name
}
