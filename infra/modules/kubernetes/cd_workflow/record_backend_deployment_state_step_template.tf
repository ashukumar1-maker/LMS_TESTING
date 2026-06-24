locals {
  # Argo Template object; see README.md for the upstream Template schema.
  record_backend_deployment_state_step_template = {
    name               = "record-final-backend-cd-state"
    serviceAccountName = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
    inputs = {
      parameters = [
        { name = "backend-hash" },
        { name = "desired-image" },
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
            "backend_hash": "{{inputs.parameters.backend-hash}}",
            "backend_image": "{{inputs.parameters.desired-image}}"
          }
        }
        JSON
        )"
        EOT
      ]
    }
  }
}
