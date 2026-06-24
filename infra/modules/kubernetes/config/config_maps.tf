resource "kubernetes_config_map_v1" "backend_env" {
  metadata {
    name      = var.backend_config_map_name
    namespace = kubernetes_namespace_v1.backend.metadata[0].name

    labels = {
      environment = var.environment
      managed-by  = "terraform"
      service     = "backend"
    }
  }

  data = var.backend_env_vars
}

resource "kubernetes_config_map_v1" "backend_secret_refs" {
  metadata {
    name      = var.backend_secret_refs_config_map_name
    namespace = kubernetes_namespace_v1.backend.metadata[0].name

    labels = {
      environment = var.environment
      managed-by  = "terraform"
      service     = "backend"
    }
  }

  data = local.backend_secret_names
}
