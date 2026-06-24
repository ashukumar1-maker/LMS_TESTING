locals {
  # Argo resource templates create short-lived Kubernetes Jobs in the backend
  # namespace so the tasks can use backend-local service accounts, ConfigMaps,
  # Secrets, database connectivity, and provider-specific storage mounts.
  backend_cd_task_step_templates = [
    for task in var.backend_cd_tasks : {
      name = "backend-cd-task-${task.name}"
      inputs = {
        parameters = [
          { name = "desired-image" },
        ]
      }
      resource = {
        action           = "create"
        successCondition = "status.succeeded > 0"
        failureCondition = "status.failed > ${task.max_retries}"
        manifest = yamlencode({
          apiVersion = "batch/v1"
          kind       = "Job"
          metadata = {
            name      = "{{workflow.name}}-${task.name}"
            namespace = var.backend_namespace
            labels = merge(local.labels, {
              "backend-cd-task" = task.name
            })
          }
          spec = {
            backoffLimit            = task.max_retries
            activeDeadlineSeconds   = task.timeout_seconds
            ttlSecondsAfterFinished = task.ttl_seconds_after_finish
            template = {
              metadata = {
                labels = merge(
                  local.labels,
                  {
                    "backend-cd-task" = task.name
                  },
                  local.cloud == "azure" ? {
                    "azure.workload.identity/use" = "true"
                  } : {}
                )
                annotations = local.cloud == "gcp" ? {
                  "gke-gcsfuse/volumes" = "true"
                } : {}
              }
              spec = {
                serviceAccountName = var.backend_service_account_name
                restartPolicy      = "Never"
                containers = [
                  {
                    name    = task.name
                    image   = "{{inputs.parameters.desired-image}}"
                    command = ["/bin/sh", "-c"]
                    args = [
                      local.cloud == "gcp" ? "until [ -S \"/cloudsql/${var.cloud_sql_instance_connection_name}/.s.PGSQL.5432\" ]; do sleep 1; done; exec /opt/venv/bin/python -m ${task.python_module}" : "exec /opt/venv/bin/python -m ${task.python_module}",
                    ]
                    envFrom = [
                      {
                        configMapRef = {
                          name = var.backend_env_config_map_name
                        }
                      },
                      {
                        secretRef = {
                          name = var.backend_secret_name
                        }
                      },
                    ]
                    resources = {
                      requests = {
                        cpu    = "1000m"
                        memory = "512Mi"
                      }
                      limits = {
                        cpu    = "1000m"
                        memory = "512Mi"
                      }
                    }
                    volumeMounts = [
                      for mount in var.backend_storage_volume_mounts :
                      {
                        name      = mount.name
                        mountPath = mount.mount_path
                      }
                    ]
                  }
                ]
                initContainers = [
                  for container in var.backend_database_sidecar_containers : {
                    name            = container.name
                    image           = container.image
                    imagePullPolicy = container.image_pull_policy
                    restartPolicy   = "Always"
                    args            = container.args
                    securityContext = {
                      runAsNonRoot = container.run_as_non_root
                    }
                    resources = container.resources
                    volumeMounts = [
                      for mount in container.volume_mounts : {
                        name      = mount.name
                        mountPath = mount.mount_path
                      }
                    ]
                  }
                ]
                volumes = [
                  for volume in var.backend_storage_volumes : merge(
                    {
                      name = volume.name
                    },
                    volume.empty_dir ? {
                      emptyDir = {}
                    } : {},
                    volume.csi_enabled ? {
                      csi = {
                        driver           = volume.csi.driver
                        readOnly         = volume.csi.read_only
                        volumeAttributes = volume.csi.volume_attributes
                      }
                    } : {}
                  )
                ]
              }
            }
          }
        })
      }
    }
  ]
}
