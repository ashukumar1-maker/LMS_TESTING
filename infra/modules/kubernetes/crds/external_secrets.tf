locals {
  external_secrets_workload_identity_annotation_keys = {
    gcp   = "iam.gke.io/gcp-service-account"
    azure = "azure.workload.identity/client-id"
  }

  external_secrets_pod_labels = lower(var.cloud) == "azure" ? {
    "azure.workload.identity/use" = "true"
  } : {}
}

resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = var.external_secrets_namespace

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_chart_version
  namespace  = kubernetes_namespace_v1.external_secrets.metadata[0].name

  values = [
    yamlencode(
      merge(
        {
          installCRDs = true
          serviceAccount = {
            create = true
            name   = var.external_secrets_service_account_name
            annotations = {
              (local.external_secrets_workload_identity_annotation_keys[lower(var.cloud)]) = var.external_secrets_workload_identity
            }
          }
        },
        length(local.external_secrets_pod_labels) > 0 ? {
          podLabels = local.external_secrets_pod_labels
        } : {}
      )
    )
  ]
}
