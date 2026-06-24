locals {
  # Shared backend pod storage contract used by the runtime backend Deployment
  # and deployment-time backend CD task Jobs. Keep these shapes aligned with
  # `backend_storage_volume_mounts` and `backend_storage_volumes` in
  # ../cd_workflow/variables.tf.
  backend_storage_volume_mounts = (
    local.cloud == "gcp" ? [
      {
        name       = "gcs-bucket-mount"
        mount_path = "/mnt/gcs"
      },
      {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      },
      ] : [
      {
        name       = "azure-blob-mount"
        mount_path = "/mnt/blob"
      },
    ]
  )

  backend_storage_volumes = (
    local.cloud == "gcp" ? [
      {
        name        = "cloudsql"
        empty_dir   = true
        csi_enabled = false
        csi = {
          driver            = ""
          read_only         = false
          volume_attributes = tomap({})
        }
      },
      {
        name        = "gcs-bucket-mount"
        empty_dir   = false
        csi_enabled = true
        csi = {
          driver    = "gcsfuse.csi.storage.gke.io"
          read_only = false
          volume_attributes = tomap({
            bucketName   = coalesce(var.gcs_bucket_name, "")
            mountOptions = local.gcs_mount_options
          })
        }
      },
      ] : [
      {
        name        = "azure-blob-mount"
        empty_dir   = false
        csi_enabled = true
        csi = {
          driver    = "blob.csi.azure.com"
          read_only = false
          volume_attributes = tomap({
            containerName                  = coalesce(var.azure_storage_container_name, "")
            storageAccount                 = coalesce(var.azure_storage_account_name, "")
            resourceGroup                  = coalesce(var.azure_storage_resource_group_name, "")
            protocol                       = "fuse"
            clientID                       = var.backend_workload_identity
            tenantID                       = coalesce(var.azure_tenant_id, "")
            mountWithWorkloadIdentityToken = "true"
          })
        }
      },
    ]
  )
}
