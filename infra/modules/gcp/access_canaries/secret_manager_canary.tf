resource "google_project_service" "secretmanager_api" {
  project                    = var.gcp_project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_password" "platform_admin_api_key" {
  length  = 40
  special = false
}

module "canary_secret" {
  source = "../secret"

  gcp_project_id       = var.gcp_project_id
  environment          = var.environment
  secret_name          = "ciridae-platform-admin-api-key"
  initial_secret_value = random_password.platform_admin_api_key.result
  secret_prefix        = ""

  labels = {
    purpose     = "service-credentials"
    environment = var.environment
  }

  depends_on = [google_project_service.secretmanager_api]
}
