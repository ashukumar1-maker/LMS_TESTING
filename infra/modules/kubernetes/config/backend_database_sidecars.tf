locals {
  # Shared backend database sidecar contract used by the runtime backend
  # Deployment and deployment-time backend CD task Jobs. Runtime pods render
  # these as sidecar containers; CD task Jobs render them as restartable init
  # containers. Keep this shape aligned with
  # `backend_database_sidecar_containers` in ../cd_workflow/variables.tf.
  backend_database_sidecar_containers = local.cloud == "gcp" ? [
    {
      name              = "cloud-sql-proxy"
      image             = var.cloud_sql_proxy_image
      image_pull_policy = "IfNotPresent"
      args = [
        "--private-ip",
        "--unix-socket=/cloudsql",
        coalesce(var.cloud_sql_instance_connection_name, ""),
      ]
      run_as_non_root = true
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
      volume_mounts = [
        for mount in local.backend_storage_volume_mounts :
        mount if mount.name == "cloudsql"
      ]
    },
  ] : []
}
