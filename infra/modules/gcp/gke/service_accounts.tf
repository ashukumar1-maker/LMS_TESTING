resource "google_service_account" "node" {
  project      = var.gcp_project_id
  account_id   = local.node_service_account_id
  display_name = "GKE node service account for ${var.environment}"

  depends_on = [
    google_project_service.iam_api,
  ]
}

resource "google_service_account" "external_secrets" {
  project      = var.gcp_project_id
  account_id   = local.external_secrets_service_account_id
  display_name = "External Secrets service account for ${var.environment}"

  depends_on = [
    google_project_service.iam_api,
  ]
}

resource "google_project_iam_member" "node_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_default_service_account" {
  project = var.gcp_project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_monitoring_viewer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_artifact_registry_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_service_account_iam_member" "external_secrets_workload_identity_user" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.external_secrets_identity_member

  depends_on = [
    google_container_cluster.default,
    google_project_service.secretmanager_api,
    google_project_service.iamcredentials_api,
  ]
}
