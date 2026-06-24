terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

locals {
  # Service account IDs must be 6-30 characters long.
  service_account_ids = {
    workflow_submitter = "${var.environment}-argo-submit"
    terraform_apply    = "${var.environment}-tf-apply-sa"
    source_inspector   = "${var.environment}-source-inspect"
    backend_builder    = "${var.environment}-backend-build"
    frontend_deployer  = "${var.environment}-frontend-deploy"
    cdn_invalidator    = "${var.environment}-cdn-invalidate"
  }

  kubernetes_service_accounts = {
    workflow_orchestrator = "${var.environment}-workflow-orchestrator"
    terraform_apply       = "${var.environment}-terraform-apply"
    source_inspector      = "${var.environment}-source-inspector"
    backend_builder       = "${var.environment}-backend-builder"
    backend_rollout       = "${var.environment}-backend-rollout"
    frontend_deployer     = "${var.environment}-frontend-deployer"
    cdn_invalidator       = "${var.environment}-cdn-invalidator"
  }

  workflow_parameter_names = [
    "commit-sha",
    "source-auth-secret-name",
    "deployment-mode",
  ]

  workload_identity_members = {
    terraform_apply   = local.kubernetes_service_accounts.terraform_apply
    source_inspector  = local.kubernetes_service_accounts.source_inspector
    backend_builder   = local.kubernetes_service_accounts.backend_builder
    frontend_deployer = local.kubernetes_service_accounts.frontend_deployer
    cdn_invalidator   = local.kubernetes_service_accounts.cdn_invalidator
  }
}

resource "google_project_service" "iam_api" {
  project                    = var.gcp_project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "secretmanager" {
  project                    = var.gcp_project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_secret_manager_secret" "sentry_auth_token" {
  project   = var.gcp_project_id
  secret_id = "${var.environment}-sentry-auth-token"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "sentry_auth_token_dummy_version" {
  secret      = google_secret_manager_secret.sentry_auth_token.id
  secret_data = "PLACEHOLDER_REPLACE_WITH_REAL_TOKEN"
}

resource "google_service_account" "workflow_submitter" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.workflow_submitter
  display_name = "Argo workflow submitter for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_service_account" "terraform_apply" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.terraform_apply
  display_name = "Terraform apply workflow task for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_service_account" "backend_builder" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.backend_builder
  display_name = "Backend image build workflow task for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_service_account" "source_inspector" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.source_inspector
  display_name = "Source inspection workflow task for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_service_account" "frontend_deployer" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.frontend_deployer
  display_name = "Frontend deployment workflow task for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_service_account" "cdn_invalidator" {
  project      = var.gcp_project_id
  account_id   = local.service_account_ids.cdn_invalidator
  display_name = "CDN invalidation workflow task for ${var.environment}"
  depends_on   = [google_project_service.iam_api]
}

resource "google_project_iam_member" "workflow_submitter_gkehub_viewer" {
  project    = var.gcp_project_id
  role       = "roles/gkehub.viewer"
  member     = "serviceAccount:${google_service_account.workflow_submitter.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "workflow_submitter_gateway_editor" {
  project    = var.gcp_project_id
  role       = "roles/gkehub.gatewayEditor"
  member     = "serviceAccount:${google_service_account.workflow_submitter.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "terraform_apply_owner" {
  project    = var.gcp_project_id
  role       = "roles/owner"
  member     = "serviceAccount:${google_service_account.terraform_apply.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_storage_bucket_iam_member" "terraform_apply_state_admin" {
  bucket     = var.tf_state_bucket_name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${google_service_account.terraform_apply.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "backend_builder_artifact_writer" {
  project    = var.gcp_project_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.backend_builder.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "source_inspector_artifact_reader" {
  project    = var.gcp_project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.source_inspector.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_storage_bucket_iam_member" "frontend_deployer_write" {
  bucket     = var.frontend_bucket_name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${google_service_account.frontend_deployer.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_secret_manager_secret_iam_member" "frontend_deployer_sentry_token_accessor" {
  project   = var.gcp_project_id
  secret_id = google_secret_manager_secret.sentry_auth_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.frontend_deployer.email}"
}

resource "google_project_iam_member" "cdn_invalidator_load_balancer_admin" {
  project    = var.gcp_project_id
  role       = "roles/compute.loadBalancerAdmin"
  member     = "serviceAccount:${google_service_account.cdn_invalidator.email}"
  depends_on = [google_project_service.iam_api]
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each = local.workload_identity_members

  service_account_id = {
    terraform_apply   = google_service_account.terraform_apply.name
    source_inspector  = google_service_account.source_inspector.name
    backend_builder   = google_service_account.backend_builder.name
    frontend_deployer = google_service_account.frontend_deployer.name
    cdn_invalidator   = google_service_account.cdn_invalidator.name
  }[each.key]
  role   = "roles/iam.workloadIdentityUser"
  member = "serviceAccount:${var.workload_identity_pool}[${var.workflow_namespace}/${each.value}]"
}
