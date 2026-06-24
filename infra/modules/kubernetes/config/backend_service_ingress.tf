resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = var.service_name
    namespace = local.backend_namespace
    labels    = local.labels

    annotations = {}
  }

  spec {
    selector = {
      app = var.deployment_name
    }

    port {
      name         = "http"
      port         = 80
      target_port  = "http"
      app_protocol = "http"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "cert_manager_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = var.cert_manager_cluster_issuer_name
      labels = local.labels
    }
    spec = {
      acme = merge(
        {
          server = var.cert_manager_acme_server
          privateKeySecretRef = {
            name = "${var.cert_manager_cluster_issuer_name}-account-key"
          }
          solvers = [
            {
              http01 = {
                ingress = {
                  ingressClassName = var.ingress_class_name
                }
              }
            },
          ]
        },
        var.cert_manager_acme_email == null ? {} : {
          email = var.cert_manager_acme_email
        }
      )
    }
  }
}

resource "kubernetes_ingress_v1" "backend" {
  metadata {
    name      = var.ingress_name
    namespace = local.backend_namespace
    labels    = local.labels

    annotations = {
      "cert-manager.io/cluster-issuer" = kubernetes_manifest.cert_manager_cluster_issuer.manifest.metadata.name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [local.backend_host]
      secret_name = var.ingress_tls_secret_name
    }

    rule {
      host = local.backend_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.backend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
