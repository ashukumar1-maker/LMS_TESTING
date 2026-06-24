locals {
  # Argo Template object; see ../README.md and the shared Kubernetes CD workflow README for schema context.
  invalidate_frontend_cache_step_template = {
    name               = "cdn-invalidate"
    serviceAccountName = var.step_service_account_name
    metadata = {
      labels = {
        "azure.workload.identity/use" = "true"
      }
    }
    container = {
      image   = var.azure_cli_image
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail

        az login \
          --service-principal \
          --username "$${AZURE_CLIENT_ID}" \
          --tenant "$${AZURE_TENANT_ID}" \
          --federated-token "$(cat "$${AZURE_FEDERATED_TOKEN_FILE}")" \
          --output none

        az afd endpoint purge \
          --subscription "${var.azure_subscription_id}" \
          --resource-group "${var.resource_group_name}" \
          --profile-name "${var.frontdoor_profile_name}" \
          --endpoint-name "${var.frontdoor_endpoint_name}" \
          --domains "${var.frontend_domain_name}" \
          --content-paths "/*"
        EOT
      ]
    }
  }
}
