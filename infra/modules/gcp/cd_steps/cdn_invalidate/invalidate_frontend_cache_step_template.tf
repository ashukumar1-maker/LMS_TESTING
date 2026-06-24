locals {
  # Argo Template object; see ../README.md and the shared Kubernetes CD workflow README for schema context.
  invalidate_frontend_cache_step_template = {
    name               = "cdn-invalidate"
    serviceAccountName = var.step_service_account_name
    container = {
      image   = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        gcloud compute url-maps invalidate-cdn-cache "${var.frontend_url_map_name}" \
          --project "${var.gcp_project_id}" \
          --path "/*"
        EOT
      ]
    }
  }
}
