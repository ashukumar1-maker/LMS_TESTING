resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = var.deployment_name
    namespace = local.backend_namespace
    labels    = local.labels
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = {
        app = var.deployment_name
      }
    }

    template {
      metadata {
        labels = merge(
          local.labels,
          local.cloud == "azure" ? {
            "azure.workload.identity/use" = "true"
          } : {}
        )
        annotations = merge(
          {
            "checksum/backend-env"         = sha256(jsonencode(var.backend_env_vars))
            "checksum/backend-secret-refs" = sha256(jsonencode(var.backend_secret_refs))
          },
          local.cloud == "gcp" ? {
            "gke-gcsfuse/volumes" = "true"
          } : {}
        )
      }

      spec {
        service_account_name = kubernetes_service_account_v1.backend.metadata[0].name

        container {
          name              = var.container_name
          image             = var.image
          image_pull_policy = "Always"
          command           = ["/opt/venv/bin/uvicorn"]
          args              = ["src.server:app", "--host", "0.0.0.0", "--port", tostring(var.container_port)]

          port {
            name           = "http"
            container_port = var.container_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.backend_env.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = local.backend_secret_names
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = local.backend_secret_name
                  key  = env.key
                }
              }
            }
          }

          startup_probe {
            http_get {
              path = var.health_check_path
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 10
          }

          readiness_probe {
            http_get {
              path = var.health_check_path
              port = "http"
            }
            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 3
          }

          liveness_probe {
            http_get {
              path = var.health_check_path
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 30
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          dynamic "volume_mount" {
            for_each = local.backend_storage_volume_mounts

            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
            }
          }
        }

        dynamic "container" {
          for_each = local.backend_database_sidecar_containers

          content {
            name              = container.value.name
            image             = container.value.image
            image_pull_policy = container.value.image_pull_policy
            args              = container.value.args

            security_context {
              run_as_non_root = container.value.run_as_non_root
            }

            resources {
              requests = container.value.resources.requests
              limits   = container.value.resources.limits
            }

            dynamic "volume_mount" {
              for_each = container.value.volume_mounts

              content {
                name       = volume_mount.value.name
                mount_path = volume_mount.value.mount_path
              }
            }
          }
        }

        dynamic "volume" {
          for_each = local.backend_storage_volumes

          content {
            name = volume.value.name

            dynamic "empty_dir" {
              for_each = volume.value.empty_dir ? [1] : []
              content {}
            }

            dynamic "csi" {
              for_each = volume.value.csi_enabled ? [volume.value.csi] : []
              content {
                driver            = csi.value.driver
                read_only         = csi.value.read_only
                volume_attributes = csi.value.volume_attributes
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas,
      spec[0].template[0].spec[0].container[0].image,
    ]
  }

  depends_on = [
    module.secret_link,
  ]
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "backend" {
  metadata {
    name      = var.deployment_name
    namespace = local.backend_namespace
    labels    = local.labels
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.backend.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.target_memory_utilization
        }
      }
    }
  }
}
