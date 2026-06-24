terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

#! The bucekt is detected in scripts by its name.
#! Do not alter the naming pattern.
locals {
  bucket_name = "${var.project_id}-${var.environment}-tfstate"
}

resource "google_project_service" "storage_api" {
  project                    = var.gcp_project_id
  service                    = "storage.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_storage_bucket" "tfstate" {
  project                     = var.gcp_project_id
  name                        = local.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"

  labels = {
    environment = var.environment
    service     = "terraform-state"
  }

  versioning {
    enabled = true
  }

  # Prevent accidental deletion of storage bucket
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.storage_api,
  ]
}
