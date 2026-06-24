locals {
  # Argo Template object; see README.md for the upstream Template schema.
  rollout_backend_deployment_step_template = {
    name               = "backend-rollout"
    serviceAccountName = kubernetes_service_account_v1.step_instances["backend_rollout"].metadata[0].name
    inputs = {
      parameters = [
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
        kubectl -n "${var.backend_namespace}" set image \
          "deployment/${var.backend_deployment_name}" \
          "${var.backend_container_name}={{inputs.parameters.desired-image}}"
        kubectl -n "${var.backend_namespace}" rollout status \
          "deployment/${var.backend_deployment_name}" \
          --timeout=600s
        EOT
      ]
    }
  }
}
