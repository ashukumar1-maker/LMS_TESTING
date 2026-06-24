resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = var.ingress_nginx_namespace

    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name

  values = [
    yamlencode({
      controller = {
        ingressClassResource = {
          name    = "nginx"
          enabled = true
          default = false
        }
        service = {
          annotations    = var.ingress_nginx_service_annotations
          loadBalancerIP = var.ingress_nginx_load_balancer_ip
        }
      }
    })
  ]
}
