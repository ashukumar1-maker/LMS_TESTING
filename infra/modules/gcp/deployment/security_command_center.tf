# SCC service-agent IAM is intentionally not managed here.
# The agents are created during SCC activation, and if SCC is active at the org level,
# project-level agents might not exist for this project.
resource "google_project_service" "security_command_center_api" {
  project                    = var.gcp_project_id
  service                    = "securitycenter.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "security_command_center_management_api" {
  project                    = var.gcp_project_id
  service                    = "securitycentermanagement.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
