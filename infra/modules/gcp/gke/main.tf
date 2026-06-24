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
  cluster_name                        = "${var.environment}-gke"
  node_service_account_id             = "${var.environment}-gke-node"
  external_secrets_service_account_id = "${var.environment}-external-secrets"
  external_secrets_identity_member    = "serviceAccount:${local.workload_identity_pool}[${var.external_secrets_kubernetes_namespace}/${var.external_secrets_kubernetes_service_account_name}]"
  node_locations                      = var.is_dev ? ["${var.region}-a"] : ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  node_pool_initial_node_count        = var.is_dev ? 1 : var.node_pool_initial_node_count
  node_pool_min_node_count            = var.is_dev ? 1 : var.node_pool_min_node_count
  node_pool_max_node_count            = var.is_dev ? 4 : var.node_pool_max_node_count
  workload_identity_pool              = "${var.gcp_project_id}.svc.id.goog"
}

data "google_project" "default" {
  project_id = var.gcp_project_id

  depends_on = [
    google_project_service.cloudresourcemanager_api,
  ]
}
