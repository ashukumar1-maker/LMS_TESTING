resource "kubernetes_namespace_v1" "backend" {
  metadata {
    name = var.backend_namespace

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}
