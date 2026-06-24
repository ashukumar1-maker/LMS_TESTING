terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.47"
    }
  }
}

locals {
  service_name                = "${var.environment}-backend"
  container_image_uri         = "${google_artifact_registry_repository.default.location}-docker.pkg.dev/${google_artifact_registry_repository.default.project}/${google_artifact_registry_repository.default.repository_id}/${var.default_container_name}"
  default_container_image_uri = "${local.container_image_uri}:${var.default_container_tag}"
  bucket_mount_path           = "/mnt/gcs"
  default_gcs_mount_options   = ["max-conns-per-host=256"]
  gcs_mount_options = var.bucket_file_cache_size != null ? concat(local.default_gcs_mount_options, [
    "implicit-dirs",
    "cache-dir=/tmp/gcs-cache",
    "file-cache-max-size-mb=${var.bucket_file_cache_size}",
    "file-cache-cache-file-for-range-read",
  ]) : local.default_gcs_mount_options
}

resource "google_project_service" "artifact_registry_api" {
  project                    = var.gcp_project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "container_analysis_api" {
  project                    = var.gcp_project_id
  service                    = "containeranalysis.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "container_scanning_api" {
  project                    = var.gcp_project_id
  service                    = "containerscanning.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}


resource "google_project_service" "google_compute_engine_api" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
