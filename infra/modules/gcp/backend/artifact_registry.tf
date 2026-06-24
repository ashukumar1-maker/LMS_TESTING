locals {
  artifact_registry_description = "Docker repository for the ${local.service_name} service (${var.environment} environment)."
}

resource "google_artifact_registry_repository" "default" {
  project       = var.gcp_project_id
  location      = var.region
  repository_id = local.service_name # Use the derived service name
  description   = local.artifact_registry_description
  format        = "DOCKER"

  vulnerability_scanning_config {
    enablement_config = "INHERITED"
  }

  # Ensure the repository is private
  # No explicit 'public' flag means it defaults to private access controlled by IAM

  depends_on = [
    google_project_service.artifact_registry_api,
    google_project_service.container_analysis_api,
    google_project_service.container_scanning_api,
  ]
}
