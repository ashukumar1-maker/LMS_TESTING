output "artifact_registry_repository_id" {
  description = "The ID of the Artifact Registry repository."
  value       = module.deployment.artifact_registry_repository_id
}

output "api_url" {
  description = "The URL of the deployed API."
  value       = module.deployment.api_url
}

output "frontend_url" {
  description = "The URL of the frontend."
  value       = module.deployment.frontend_url
}

output "frontend_env_vars" {
  description = "Additional frontend build environment variables sourced from Terraform state."
  value       = var.frontend_env_vars
}

output "backend_egress_static_ip_addresses" {
  description = "Static external IP addresses used by backend Cloud NAT egress."
  value       = module.deployment.backend_egress_static_ip_addresses
}

output "kubernetes_cluster_name" {
  description = "The Kubernetes cluster name."
  value       = module.deployment.kubernetes_cluster_name
}

output "kubernetes_cluster_location" {
  description = "The Kubernetes cluster location."
  value       = module.deployment.kubernetes_cluster_location
}

output "kubernetes_cluster_id" {
  description = "The Kubernetes cluster resource ID."
  value       = module.deployment.kubernetes_cluster_id
}

output "gke_fleet_membership_name" {
  description = "The GKE Fleet membership name."
  value       = module.deployment.gke_fleet_membership_name
}

output "gke_connect_gateway_host" {
  description = "Connect Gateway host for Kubernetes and Helm providers."
  value       = module.deployment.gke_connect_gateway_host
}

output "gke_workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster."
  value       = module.deployment.gke_workload_identity_pool
}

output "gke_node_service_account_email" {
  description = "Email of the GKE node service account."
  value       = module.deployment.gke_node_service_account_email
}

output "gke_external_secrets_service_account_email" {
  description = "Email of the External Secrets Google service account."
  value       = module.deployment.gke_external_secrets_service_account_email
}

output "backend_kubernetes_namespace" {
  description = "Namespace for future backend Kubernetes resources."
  value       = module.deployment.backend_kubernetes_namespace
}

output "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for future backend workloads."
  value       = module.deployment.backend_kubernetes_service_account_name
}

output "external_secrets_kubernetes_namespace" {
  description = "Namespace for the future External Secrets Operator."
  value       = module.deployment.external_secrets_kubernetes_namespace
}

output "external_secrets_kubernetes_service_account_name" {
  description = "Kubernetes service account name used by the future External Secrets Operator."
  value       = module.deployment.external_secrets_kubernetes_service_account_name
}

output "dns_nameservers" {
  description = "Nameservers for the DNS zone."
  value       = module.deployment.dns_nameservers
}

output "ds_record_values" {
  description = "DS record values for DNSSEC."
  value       = module.deployment.ds_record_values
}

output "ds_record_instructions" {
  description = "Instructions for DS records."
  value       = module.deployment.ds_record_instructions
}

output "sentry_setup_instructions" {
  description = "Instructions for setting up Sentry auth token after first terraform apply."
  value       = module.deployment.sentry_setup_instructions
}

output "terraform_apply_service_account_email" {
  description = "The email of the service account used by Argo Terraform apply workflow step instances."
  value       = module.deployment.terraform_apply_service_account_email
}

output "workflow_submitter_service_account_email" {
  description = "The email of the service account external callers should use to submit Argo deployment workflows."
  value       = module.deployment.workflow_submitter_service_account_email
}

output "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  value       = module.deployment.workflow_namespace
}

output "workflow_template_name" {
  description = "Name of the Argo deployment WorkflowTemplate."
  value       = module.deployment.workflow_template_name
}

output "crucible_deployment_contract_version" {
  description = "The deployment contract version exposed to Crucible."
  value       = module.deployment.crucible_deployment_contract_version
}

output "workflow_required_parameters" {
  description = "Required parameters for submitting the Argo deployment workflow."
  value       = module.deployment.workflow_required_parameters
}

output "backend_kubernetes_deployment_name" {
  description = "Backend Kubernetes Deployment name."
  value       = module.kubernetes_config.backend_deployment_name
}

output "backend_kubernetes_container_name" {
  description = "Backend application container name."
  value       = module.kubernetes_config.backend_container_name
}

output "backend_kubernetes_service_name" {
  description = "Backend Kubernetes Service name."
  value       = module.kubernetes_config.backend_service_name
}

output "backend_kubernetes_ingress_name" {
  description = "Backend Kubernetes Ingress name."
  value       = module.kubernetes_config.backend_ingress_name
}

output "backend_kubernetes_hpa_name" {
  description = "Backend Kubernetes HorizontalPodAutoscaler name."
  value       = module.kubernetes_config.backend_horizontal_pod_autoscaler_name
}
