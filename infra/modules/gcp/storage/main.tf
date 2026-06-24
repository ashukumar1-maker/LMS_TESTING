terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

locals {
  bucket_name = "${var.project_id}-${var.environment}-${var.bucket_name_suffix}"
}

resource "google_project_service" "storage_api" {
  project                    = var.gcp_project_id
  service                    = "storage.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_storage_bucket" "default" {
  project                     = var.gcp_project_id
  name                        = local.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  storage_class               = "STANDARD" # Or your preferred storage class

  labels = {
    environment = var.environment
    service     = "application-storage"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state                 = "ANY"
      days_since_noncurrent_time = 7 # Or your preferred retention for noncurrent versions
    }
  }

  # Add this CORS configuration
  cors {
    origin = compact(distinct(concat(
      var.is_dev ? ["http://localhost:3000"] : [],
      var.frontend_url != "" ? [var.frontend_url] : []
    )))
    method          = ["PUT"]
    response_header = ["Content-Type", "Content-Range", "X-Goog-Resumable"]
    max_age_seconds = 3600
  }

  # Optional: Enable for better security if not using a VPC Service Control perimeter
  # public_access_prevention = "enforced"

  # Prevent accidental deletion of storage bucket
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.storage_api,
  ]
}
