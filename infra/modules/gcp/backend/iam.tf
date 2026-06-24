resource "google_project_service" "identity_and_access_management_api" {
  project                    = var.gcp_project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# This creates a service account for backend Kubernetes workloads.
resource "google_service_account" "default" {
  project      = var.gcp_project_id
  account_id   = local.service_name # Use the derived service name for the account ID
  display_name = "Service Account for ${local.service_name}"

  depends_on = [
    google_project_service.identity_and_access_management_api,
  ]
}

# Grant Cloud SQL Client role specifically to the target instance
resource "google_project_iam_member" "cloud_run_sql_client_specific" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.default.email}"

  condition {
    title       = "Grant Cloud SQL Client to specific instance via connection name"
    description = "Only grant Cloud SQL client role for instance derived from ${var.database_connection_name}"
    expression  = "resource.name == \"projects/${var.gcp_project_id}/instances/${split(":", var.database_connection_name)[2]}\""
  }
}

# Grant Artifact Registry Reader role to the service account for the created repository
resource "google_artifact_registry_repository_iam_member" "registry_reader" {
  project    = var.gcp_project_id
  location   = google_artifact_registry_repository.default.location
  repository = google_artifact_registry_repository.default.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.default.email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_storage_access" {
  bucket = var.storage_bucket_name
  role   = "roles/storage.objectAdmin" // Allows read, write, delete objects
  member = "serviceAccount:${google_service_account.default.email}"
}

resource "google_service_account_iam_member" "backend_workload_identity_user" {
  service_account_id = google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.workload_identity_pool}[${var.backend_kubernetes_namespace}/${var.backend_kubernetes_service_account_name}]"
}
