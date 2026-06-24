terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

locals {
  cloud = lower(var.cloud)

  labels = {
    app         = var.deployment_name
    environment = var.environment
    managed-by  = "terraform"
  }

  secret_store_labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  backend_secret_names = {
    for key, ref in var.backend_secret_refs :
    key => try(split("/", ref)[3], ref)
  }

  backend_namespace = kubernetes_namespace_v1.backend.metadata[0].name
  backend_host      = "api.${var.domain_name}"
  backend_secret_fingerprint = substr(sha256(jsonencode({
    refs = var.backend_secret_refs
  })), 0, 12)
  backend_secret_name = "backend-secrets-${local.backend_secret_fingerprint}"

  gcs_mount_options = var.bucket_file_cache_size != null ? join(",", [
    "max-conns-per-host=256",
    "implicit-dirs",
    "cache-dir=/tmp/gcs-cache",
    "file-cache-max-size-mb=${var.bucket_file_cache_size}",
    "file-cache-cache-file-for-range-read",
  ]) : "max-conns-per-host=256"
}
