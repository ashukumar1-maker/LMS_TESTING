locals {
  # Argo Template object; see README.md for the upstream Template schema.
  delete_temporary_source_auth_secret_step_template = {
    name               = "delete-source-auth-secret"
    serviceAccountName = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
    container = {
      image   = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        apt-get update && apt-get install -y kubectl
        if [ -n "{{workflow.parameters.source-auth-secret-name}}" ]; then
          kubectl -n ${var.namespace} delete secret "{{workflow.parameters.source-auth-secret-name}}" --ignore-not-found=true
        fi
        EOT
      ]
    }
  }
}
