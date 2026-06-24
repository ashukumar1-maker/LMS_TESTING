resource "google_project_iam_audit_config" "secretmanager_data_read" {
  project = var.gcp_project_id
  service = "secretmanager.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
}

resource "google_project_iam_audit_config" "storage_data_read" {
  project = var.gcp_project_id
  service = "storage.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
}
