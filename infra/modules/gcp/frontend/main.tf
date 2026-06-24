terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

locals {
  bucket_name = "${var.project_id}-${var.environment}-frontend"
}

resource "google_project_service" "compute_api" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
