locals {
  workflow_parameters = [
    { name = "commit-sha" },
    { name = "source-auth-secret-name" },
    { name = "deployment-mode" },
  ]

  infra_mode_when    = "'{{workflow.parameters.deployment-mode}}' == 'INFRA_ONLY' || '{{workflow.parameters.deployment-mode}}' == 'FULL'"
  backend_mode_when  = "'{{workflow.parameters.deployment-mode}}' == 'BACKEND_ONLY' || '{{workflow.parameters.deployment-mode}}' == 'FULL'"
  frontend_mode_when = "'{{workflow.parameters.deployment-mode}}' == 'FRONTEND_ONLY' || '{{workflow.parameters.deployment-mode}}' == 'FULL'"
}
