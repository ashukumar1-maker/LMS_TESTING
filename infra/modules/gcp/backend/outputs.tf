output "service_name" {
  description = "The backend service name used for Artifact Registry images and GCP resources."
  value       = local.service_name
}

output "service_account_email" {
  description = "The email of the created backend workload service account."
  value       = google_service_account.default.email
}

output "artifact_repository_id" {
  description = "The resource ID of the created Artifact Registry repository."
  value       = google_artifact_registry_repository.default.id
}

output "artifact_repository_name" {
  description = "The name (repository_id) of the created Artifact Registry repository."
  value       = google_artifact_registry_repository.default.name
}

output "ingress_nginx_ip_address" {
  description = "The reserved regional static IP address assigned to the ingress-nginx controller."
  value       = google_compute_address.api_ip.address
}

output "ingress_nginx_ip_name" {
  description = "The reserved regional static IP name assigned to the ingress-nginx controller."
  value       = google_compute_address.api_ip.name
}

output "backend_runtime_env_vars" {
  description = "Non-secret backend runtime environment variables."
  value       = local.backend_env_vars
}

output "backend_secret_refs" {
  description = "Secret Manager refs for backend runtime secrets."
  value       = local.backend_secret_refs
}

output "default_container_image_uri" {
  description = "Default backend container image URI used before the first deployment build."
  value       = local.default_container_image_uri
}
