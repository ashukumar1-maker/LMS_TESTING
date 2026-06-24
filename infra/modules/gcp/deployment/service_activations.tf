resource "google_project_service" "cloud_kms_api" {
  project                    = var.gcp_project_id
  service                    = "cloudkms.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
