resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = var.cert_manager_namespace

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
    })
  ]
}
