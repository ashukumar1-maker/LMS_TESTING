resource "google_storage_bucket" "frontend" {
  project       = var.gcp_project_id
  name          = local.bucket_name
  location      = var.region
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  website {
    main_page_suffix = var.main_page_suffix
    not_found_page   = var.main_page_suffix
  }

  # Prevent accidental deletion of frontend bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
