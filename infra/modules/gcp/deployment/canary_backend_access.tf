// Keep canary-specific IAM at the deployment layer because this module composes
// both the canary resources and the backend service account. That avoids
// widening the generic backend module interface with access-canary concerns.
resource "google_storage_bucket_iam_member" "backend_canary_bucket_access" {
  bucket = module.access_canaries.canary_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.backend_service.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "backend_canary_secret_access" {
  project   = var.gcp_project_id
  secret_id = module.access_canaries.canary_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.backend_service.service_account_email}"
}
