terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = var.secret_store_name
      namespace = var.namespace
      labels    = coalesce(var.secret_store_labels, var.labels)
    }
    spec = {
      provider = {
        gcpsm = {
          projectID = var.gcp_project_id
        }
      }
    }
  }
}

resource "kubernetes_manifest" "external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.external_secret_name
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      refreshInterval = var.refresh_interval
      secretStoreRef = {
        kind = "SecretStore"
        name = kubernetes_manifest.secret_store.manifest.metadata.name
      }
      target = {
        name           = var.target_secret_name
        creationPolicy = "Owner"
      }
      data = [
        for key, secret_name in var.secret_names : {
          secretKey = key
          remoteRef = {
            key = secret_name
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.secret_store]
}
