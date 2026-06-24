locals {
  # Argo Template object; see README.md for the upstream Template schema.
  record_frontend_deployment_state_step_template = {
    name               = "record-final-frontend-cd-state"
    serviceAccountName = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
    inputs = {
      parameters = [
        { name = "frontend-hash" },
        { name = "frontend-env-hash" },
      ]
    }
    container = {
      image   = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        apt-get update && apt-get install -y kubectl
        kubectl -n ${var.namespace} patch configmap ${kubernetes_config_map_v1.workflow_state.metadata[0].name} --type merge -p "$(cat <<JSON
        {
          "data": {
            "frontend_hash": "{{inputs.parameters.frontend-hash}}",
            "frontend_env_hash": "{{inputs.parameters.frontend-env-hash}}"
          }
        }
        JSON
        )"
        EOT
      ]
    }
  }
}
