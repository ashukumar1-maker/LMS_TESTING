output "workflow_kubernetes_service_accounts" {
  description = "Kubernetes service account names used by deployment workflow step instances."
  value       = local.kubernetes_service_accounts
}

output "workflow_step_service_account_identity_client_ids" {
  description = "Azure client IDs used by deployment workflow step service accounts."
  value = {
    terraform_apply   = azurerm_user_assigned_identity.task["terraform_apply"].client_id
    source_inspector  = azurerm_user_assigned_identity.task["source_inspector"].client_id
    backend_builder   = azurerm_user_assigned_identity.task["backend_builder"].client_id
    frontend_deployer = azurerm_user_assigned_identity.task["frontend_deployer"].client_id
    cdn_invalidator   = azurerm_user_assigned_identity.task["cdn_invalidator"].client_id
  }
}

output "workflow_required_parameters" {
  description = "Required parameters for submitting the deployment workflow."
  value = [
    "commit-sha",
    "source-auth-secret-name",
    "deployment-mode",
  ]
}

output "crucible_deployment_contract_version" {
  description = "The deployment contract version exposed to Crucible."
  value       = "argo_workflow_v1"
}
