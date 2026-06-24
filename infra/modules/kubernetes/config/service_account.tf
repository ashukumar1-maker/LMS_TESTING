locals {
  backend_service_account_identity_annotation_keys = {
    gcp   = "iam.gke.io/gcp-service-account"
    azure = "azure.workload.identity/client-id"
  }

  backend_service_account_identity_annotation_key = local.backend_service_account_identity_annotation_keys[lower(var.cloud)]

  backend_service_account_annotations = {
    (local.backend_service_account_identity_annotation_key) = var.backend_workload_identity
  }
}

resource "kubernetes_service_account_v1" "backend" {
  metadata {
    name      = var.service_account_name
    namespace = local.backend_namespace

    annotations = local.backend_service_account_annotations

    labels = local.labels
  }
}

resource "kubernetes_cluster_role_binding_v1" "terraform_apply_cluster_admin" {
  metadata {
    name = "${var.environment}-terraform-apply-cluster-admin"

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = var.terraform_apply_service_account_email
  }
}
