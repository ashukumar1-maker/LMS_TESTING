output "secret_id" {
  description = "The ID of the created secret"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_name" {
  description = "The full resource name of the secret"
  value       = google_secret_manager_secret.secret.name
}

output "secret_ref" {
  description = "Reference to the latest version of the secret for use in Cloud Run environment variables"
  value       = "projects/${var.gcp_project_id}/secrets/${google_secret_manager_secret.secret.secret_id}/versions/latest"
}

output "secret_version_name" {
  description = "The full resource name of the secret version"
  value       = var.ignore_secret_changes ? google_secret_manager_secret_version.secret_version_static[0].name : google_secret_manager_secret_version.secret_version_dynamic[0].name
}