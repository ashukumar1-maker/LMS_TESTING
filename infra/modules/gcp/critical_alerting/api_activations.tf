resource "google_project_service" "pubsub_api" {
  project                    = var.gcp_project_id
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "monitoring_api" {
  project                    = var.gcp_project_id
  service                    = "monitoring.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
