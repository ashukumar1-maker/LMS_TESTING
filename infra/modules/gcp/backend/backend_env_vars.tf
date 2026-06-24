locals {
  backend_env_vars = merge(
    {
      MOUNTED_BACKEND_GCS_BUCKET_NAME = var.storage_bucket_name
      ENVIRONMENT                     = var.environment
      GOOGLE_CLOUD_PROJECT            = var.gcp_project_id
      BACKEND_BUCKET_MOUNT_PATH       = local.bucket_mount_path
      AUTH_SERVICE_BACKEND_URL        = var.auth_service_backend_url
      PROJECT_ID                      = var.project_id
    },
    var.env_vars
  )
}
