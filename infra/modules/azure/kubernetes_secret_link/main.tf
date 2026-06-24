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
    kind       = "ClusterSecretStore"
    metadata = {
      name   = var.secret_store_name
      labels = coalesce(var.secret_store_labels, var.labels)
    }
    spec = {
      provider = {
        azurekv = {
          authType = "WorkloadIdentity"
          vaultUrl = var.key_vault_url
          tenantId = var.tenant_id
          serviceAccountRef = {
            name      = var.external_secrets_service_account_name
            namespace = var.external_secrets_namespace
          }
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
        kind = "ClusterSecretStore"
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
