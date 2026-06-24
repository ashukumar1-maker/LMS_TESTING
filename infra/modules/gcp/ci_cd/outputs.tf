output "terraform_apply_service_account_email" {
  description = "Google service account email used by Argo Terraform apply workflow step instances."
  value       = google_service_account.terraform_apply.email
}

output "workflow_submitter_service_account_email" {
  description = "Google service account external callers use to submit deployment workflows."
  value       = google_service_account.workflow_submitter.email
}

output "backend_builder_service_account_email" {
  description = "Google service account used by backend image build workflow step instances."
  value       = google_service_account.backend_builder.email
}

output "source_inspector_service_account_email" {
  description = "Google service account used by source inspection workflow step instances."
  value       = google_service_account.source_inspector.email
}

output "frontend_deployer_service_account_email" {
  description = "Google service account used by frontend build/upload workflow step instances."
  value       = google_service_account.frontend_deployer.email
}

output "cdn_invalidator_service_account_email" {
  description = "Google service account used by CDN invalidation workflow step instances."
  value       = google_service_account.cdn_invalidator.email
}

output "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  value       = var.workflow_namespace
}

output "workflow_template_name" {
  description = "Name of the deployment WorkflowTemplate."
  value       = var.workflow_template_name
}

output "workflow_kubernetes_service_accounts" {
  description = "Kubernetes service account names used by deployment workflow step instances."
  value       = local.kubernetes_service_accounts
}

output "workflow_required_parameters" {
  description = "Required parameters for submitting the deployment workflow."
  value       = local.workflow_parameter_names
}

output "sentry_auth_token_secret_id" {
  description = "The ID of the Sentry auth token secret. Populate this secret with your Sentry auth token after first apply."
  value       = google_secret_manager_secret.sentry_auth_token.id
}

output "sentry_auth_token_secret_name" {
  description = "The name of the Sentry auth token secret for easy reference."
  value       = google_secret_manager_secret.sentry_auth_token.secret_id
}

output "crucible_deployment_contract_version" {
  description = "The deployment contract version exposed to Crucible."
  value       = "argo_workflow_v1"
}
