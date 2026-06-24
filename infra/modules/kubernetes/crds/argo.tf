resource "kubernetes_namespace_v1" "argo" {
  metadata {
    name = var.argo_namespace

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "helm_release" "argo_workflows" {
  name       = "argo-workflows"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-workflows"
  version    = var.argo_workflows_chart_version
  namespace  = kubernetes_namespace_v1.argo.metadata[0].name

  values = [
    yamlencode({
      crds = {
        install = true
      }
      controller = {
        workflowNamespaces = [
          kubernetes_namespace_v1.argo.metadata[0].name,
        ]
      }
      server = {
        enabled = true
      }
    })
  ]
}
