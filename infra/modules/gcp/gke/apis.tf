resource "google_project_service" "container_api" {
  project                    = var.gcp_project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "gkehub_api" {
  project                    = var.gcp_project_id
  service                    = "gkehub.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "gkeconnect_api" {
  project                    = var.gcp_project_id
  service                    = "gkeconnect.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "connectgateway_api" {
  project                    = var.gcp_project_id
  service                    = "connectgateway.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  project                    = var.gcp_project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager_api" {
  project                    = var.gcp_project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "iamcredentials_api" {
  project                    = var.gcp_project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  project                    = var.gcp_project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
