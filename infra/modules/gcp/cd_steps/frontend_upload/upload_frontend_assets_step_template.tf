locals {
  # Argo Template object; see ../README.md and the shared Kubernetes CD workflow README for schema context.
  upload_frontend_assets_step_template = {
    name               = "frontend-upload"
    serviceAccountName = var.step_service_account_name
    container = {
      image   = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        gsutil -m rsync -r /workspace/repo/frontend/dist "gs://${var.frontend_bucket_name}"
        EOT
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        }
      ]
    }
  }
}
