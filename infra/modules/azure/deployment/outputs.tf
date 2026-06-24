output "artifact_registry_repository_id" {
  description = "The ID of the Azure Container Registry."
  value       = module.backend.artifact_registry_repository_id
}

output "azure_subscription_id" {
  description = "Azure subscription ID for deployment resources."
  value       = var.azure_subscription_id
}

output "container_registry_login_server" {
  description = "Azure Container Registry login server."
  value       = module.backend.container_registry_login_server
}

output "api_url" {
  description = "The URL of the deployed API."
  value       = "https://api.${var.domain_name}"
}

output "frontend_url" {
  description = "The URL of the frontend through Azure Front Door."
  value       = module.frontend.frontend_url
}

output "resource_group_name" {
  description = "Azure resource group name for deployment resources."
  value       = azurerm_resource_group.default.name
}

output "frontend_bucket_name" {
  description = "Name of the frontend static website storage account."
  value       = azurerm_storage_account.default.name
}

output "backend_storage_account_name" {
  description = "Azure Storage account name used by backend runtime storage."
  value       = azurerm_storage_account.default.name
}

output "backend_storage_container_name" {
  description = "Azure Blob container name used by backend runtime storage."
  value       = module.storage.backend_container_name
}

output "frontend_url_map_name" {
  description = "Azure Front Door profile name used for frontend cache invalidation."
  value       = module.frontend.profile_name
}

output "frontend_cdn_endpoint_name" {
  description = "Azure Front Door endpoint name used for frontend cache invalidation."
  value       = module.frontend.endpoint_name
}

output "frontend_cdn_endpoint_host_name" {
  description = "Azure Front Door default endpoint host name."
  value       = module.frontend.endpoint_host_name
}

output "backend_egress_static_ip_addresses" {
  description = "Static external IP addresses used by backend egress."
  value       = []
}

output "kubernetes_cluster_name" {
  description = "The AKS cluster name."
  value       = module.aks.cluster_name
}

output "kubernetes_cluster_location" {
  description = "The AKS cluster location."
  value       = module.aks.cluster_location
}

output "kubernetes_cluster_id" {
  description = "The AKS cluster resource ID."
  value       = module.aks.cluster_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID used by AKS Azure Monitor."
  value       = azurerm_log_analytics_workspace.aks.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name used by AKS Azure Monitor."
  value       = azurerm_log_analytics_workspace.aks.name
}

output "gke_fleet_membership_name" {
  description = "GKE-specific output; null for Azure."
  value       = null
}

output "gke_connect_gateway_host" {
  description = "GKE-specific output; null for Azure."
  value       = null
}

output "gke_workload_identity_pool" {
  description = "GKE-specific output; null for Azure."
  value       = null
}

output "gke_node_service_account_email" {
  description = "GKE-specific output; null for Azure."
  value       = null
}

output "gke_external_secrets_service_account_email" {
  description = "GKE-specific output; null for Azure."
  value       = null
}

output "external_secrets_workload_identity" {
  description = "Azure managed identity client ID used by External Secrets Operator."
  value       = module.backend.external_secrets_identity_client_id
}

output "azure_key_vault_url" {
  description = "Azure Key Vault URL containing backend runtime secrets."
  value       = azurerm_key_vault.default.vault_uri
}

output "azure_tenant_id" {
  description = "Azure tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "backend_kubernetes_namespace" {
  description = "Namespace for backend Kubernetes resources."
  value       = local.backend_namespace
}

output "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for backend workloads."
  value       = local.backend_service_account_name
}

output "external_secrets_kubernetes_namespace" {
  description = "Namespace for the External Secrets Operator."
  value       = local.external_secrets_namespace
}

output "external_secrets_kubernetes_service_account_name" {
  description = "Kubernetes service account name used by the External Secrets Operator."
  value       = local.external_secrets_service_account_name
}

output "dns_nameservers" {
  description = "Azure DNS nameservers."
  value       = module.dns.name_servers
}

output "ds_record_values" {
  description = "DNSSEC DS records for the Azure DNS zone."
  value       = module.dns.ds_record_values
}

output "ds_record_instructions" {
  description = "Instructions for adding DNSSEC DS records."
  value       = module.dns.ds_record_instructions
}

output "sentry_auth_token_secret_id" {
  description = "The Azure Key Vault secret ID for the Sentry auth token."
  value       = module.sentry_auth_token_secret.secret_id
}

output "sentry_auth_token_secret_name" {
  description = "The Azure Key Vault secret name for the Sentry auth token."
  value       = module.sentry_auth_token_secret.secret_name
}

output "database_password_secret_id" {
  description = "The Azure Key Vault secret ID for the generated database password."
  value       = module.database_password_secret.secret_id
}

output "database_password_secret_name" {
  description = "The Azure Key Vault secret name for the generated database password."
  value       = module.database_password_secret.secret_name
}

output "sentry_setup_instructions" {
  description = "Instructions for setting up Sentry auth token after first terraform apply."
  value       = "Replace the ${module.sentry_auth_token_secret.secret_name} secret value in Key Vault ${azurerm_key_vault.default.name} with a Sentry auth token."
}

output "terraform_apply_service_account_email" {
  description = "Azure client ID used by Argo Terraform apply workflow step service account."
  value       = module.ci_cd.workflow_step_service_account_identity_client_ids.terraform_apply
}

output "workflow_submitter_service_account_email" {
  description = "Azure client ID external callers should use to submit Argo workflows."
  value       = null
}

output "backend_workload_identity" {
  description = "Azure managed identity client ID used by backend Kubernetes workloads."
  value       = module.backend.backend_identity_client_id
}

output "backend_runtime_env_vars" {
  description = "Non-secret backend runtime environment variables."
  value       = module.backend.backend_runtime_env_vars
}

output "backend_service_backend_secret_refs" {
  description = "Key Vault secret names for backend runtime secrets."
  value = merge(
    {
      for key, secret_module in module.backend_secrets :
      key => secret_module.secret_ref
    },
    {
      DATABASE_URL = module.database_url_secret.secret_ref
    }
  )
}

output "backend_default_container_image_uri" {
  description = "Default backend image URI used by Terraform-managed Kubernetes resources."
  value       = module.backend.default_container_image_uri
}

output "backend_api_ip_name" {
  description = "Static public IP name reserved for the backend ingress."
  value       = module.network.backend_public_ip_name
}

output "backend_api_ip_address" {
  description = "Static public IP address reserved for the backend ingress."
  value       = module.network.backend_public_ip_address
}

output "database_instance_connection_name" {
  description = "Azure PostgreSQL Flexible Server FQDN."
  value       = module.database.database_fqdn
}

output "terraform_state_bucket_name" {
  description = "Storage account used for Terraform state and tfvars synchronization."
  value       = azurerm_storage_account.default.name
}

output "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  value       = local.workflow_namespace
}

output "workflow_template_name" {
  description = "Name of the Argo deployment WorkflowTemplate."
  value       = local.workflow_template_name
}

output "workflow_kubernetes_service_accounts" {
  description = "Kubernetes service account names used by deployment workflow step instances."
  value       = module.ci_cd.workflow_kubernetes_service_accounts
}

output "workflow_step_service_account_emails" {
  description = "Azure client IDs used by deployment workflow step service accounts."
  value       = module.ci_cd.workflow_step_service_account_identity_client_ids
}

output "crucible_deployment_contract_version" {
  description = "The deployment contract version exposed to Crucible."
  value       = module.ci_cd.crucible_deployment_contract_version
}

output "workflow_required_parameters" {
  description = "Required parameters for submitting the Argo deployment workflow."
  value       = module.ci_cd.workflow_required_parameters
}
