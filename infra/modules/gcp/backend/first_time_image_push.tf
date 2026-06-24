data "google_project" "current" {
  project_id = var.gcp_project_id
}

resource "google_project_service" "cloudbuild_api" {
  project                    = var.gcp_project_id
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_artifact_registry_repository_iam_member" "initial_push_cloudbuild_writer" {
  project    = var.gcp_project_id
  location   = google_artifact_registry_repository.default.location
  repository = google_artifact_registry_repository.default.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "google_artifact_registry_repository_iam_member" "initial_push_compute_writer" {
  project    = var.gcp_project_id
  location   = google_artifact_registry_repository.default.location
  repository = google_artifact_registry_repository.default.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "google_project_iam_member" "compute_sa_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "google_project_iam_member" "compute_sa_logs_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_logs_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild_api,
  ]
}

resource "null_resource" "build_and_push_initial_image" {
  triggers = {
    repository_id = google_artifact_registry_repository.default.id
    image_tag     = var.default_container_tag
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit \
        --project=${var.gcp_project_id} \
        --region=${var.region} \
        --config=${path.module}/cloudbuild-initial.yaml \
        --substitutions=_IMAGE_URI="${local.container_image_uri}",_IMAGE_TAG="${var.default_container_tag}" \
        ${path.module}/../../../../backend
    EOT
  }

  depends_on = [
    google_artifact_registry_repository.default,
    google_project_service.cloudbuild_api,
    google_artifact_registry_repository_iam_member.initial_push_cloudbuild_writer,
    google_artifact_registry_repository_iam_member.initial_push_compute_writer,
    google_project_iam_member.cloudbuild_sa_storage_admin,
    google_project_iam_member.compute_sa_storage_admin,
    google_project_iam_member.compute_sa_logs_writer,
    google_project_iam_member.cloudbuild_sa_logs_writer,
  ]
}
