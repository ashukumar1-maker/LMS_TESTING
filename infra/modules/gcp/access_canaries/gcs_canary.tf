locals {
  canary_bucket_name = "${var.project_id}-${var.environment}-platform-admin-exports-${random_id.bucket_suffix.hex}"
  canary_marker_name = "exports/platform-admin-accounts-2026-01.csv"
}

resource "google_project_service" "storage_api" {
  project                    = var.gcp_project_id
  service                    = "storage.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_id" "bucket_suffix" {
  byte_length = 2
  keepers = {
    project_id  = var.project_id
    environment = var.environment
  }
}

resource "google_storage_bucket" "canary" {
  project                     = var.gcp_project_id
  name                        = local.canary_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"

  labels = {
    environment = var.environment
    purpose     = "admin-exports"
  }

  depends_on = [google_project_service.storage_api]
}

// This object is intentionally uploaded via local-exec and left unmanaged so
// Terraform never refreshes it from GCS during later plan/apply runs.
resource "null_resource" "canary_marker_upload" {
  triggers = {
    bucket_name = google_storage_bucket.canary.name
    object_name = local.canary_marker_name
    seed_v1     = "1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<'EOF' | gcloud storage cp - "gs://${google_storage_bucket.canary.name}/${local.canary_marker_name}" --project="${var.gcp_project_id}" --content-type="text/csv" --quiet
      account_id,email,role
      1001,ops@ciridae.app,admin
      EOF
    EOT
  }

  depends_on = [
    google_project_service.storage_api,
    google_storage_bucket.canary,
  ]
}
