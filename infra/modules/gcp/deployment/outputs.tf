output "artifact_registry_repository_id" {
  description = "The ID of the Artifact Registry repository."
  value       = module.backend_service.artifact_repository_id
}

output "api_url" {
  description = "The URL of the deployed API."
  value       = local.api_url
}

output "frontend_url" {
  description = "The URL of the frontend."
  value       = module.frontend.frontend_url
}

output "frontend_bucket_name" {
  description = "Name of the frontend static asset bucket."
  value       = module.frontend.bucket_name
}

output "frontend_url_map_name" {
  description = "Compute URL map name for frontend CDN cache invalidation."
  value       = module.frontend.url_map_name
}

output "backend_egress_static_ip_addresses" {
  description = "Static external IP addresses used by backend Cloud NAT egress."
  value       = google_compute_address.backend_egress_ips[*].address
}

output "gke_cluster_name" {
  description = "The GKE cluster name."
  value       = module.gke.cluster_name
}

output "gke_cluster_location" {
  description = "The GKE cluster location."
  value       = module.gke.cluster_location
}

output "gke_cluster_id" {
  description = "The GKE cluster resource ID."
  value       = module.gke.cluster_id
}

output "kubernetes_cluster_name" {
  description = "The Kubernetes cluster name."
  value       = module.gke.cluster_name
}

output "kubernetes_cluster_location" {
  description = "The Kubernetes cluster location."
  value       = module.gke.cluster_location
}

output "kubernetes_cluster_id" {
  description = "The Kubernetes cluster resource ID."
  value       = module.gke.cluster_id
}

output "gke_fleet_membership_name" {
  description = "The GKE Fleet membership name."
  value       = module.gke.fleet_membership_name
}

output "gke_connect_gateway_host" {
  description = "Connect Gateway host for Kubernetes and Helm providers."
  value       = module.gke.connect_gateway_host
}

output "gke_workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster."
  value       = module.gke.workload_identity_pool
}

output "gke_node_service_account_email" {
  description = "Email of the GKE node service account."
  value       = module.gke.node_service_account_email
}

output "gke_external_secrets_service_account_email" {
  description = "Email of the External Secrets Google service account."
  value       = module.gke.external_secrets_service_account_email
}

output "external_secrets_workload_identity" {
  description = "Google service account email used by External Secrets Operator."
  value       = module.gke.external_secrets_service_account_email
}

output "backend_kubernetes_namespace" {
  description = "Namespace for future backend Kubernetes resources."
  value       = module.gke.backend_kubernetes_namespace
}

output "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for future backend workloads."
  value       = module.gke.backend_kubernetes_service_account_name
}

output "external_secrets_kubernetes_namespace" {
  description = "Namespace for the future External Secrets Operator."
  value       = module.gke.external_secrets_kubernetes_namespace
}

output "external_secrets_kubernetes_service_account_name" {
  description = "Kubernetes service account name used by the future External Secrets Operator."
  value       = module.gke.external_secrets_kubernetes_service_account_name
}

output "dns_nameservers" {
  description = "Nameservers for the DNS zone. Add NS records in parent domain."
  value       = module.dns.name_servers
}

output "ds_record_values" {
  description = "DS record values for DNSSEC. Add these to your parent domain."
  value       = module.dns.ds_record_values
}

output "ds_record_instructions" {
  description = "Instructions for adding DS records."
  value       = module.dns.ds_record_instructions
}

output "sentry_auth_token_secret_id" {
  description = "The full resource ID of the Sentry auth token secret."
  value       = module.ci_cd.sentry_auth_token_secret_id
}

output "sentry_auth_token_secret_name" {
  description = "The name of the Sentry auth token secret."
  value       = module.ci_cd.sentry_auth_token_secret_name
}

output "terraform_apply_service_account_email" {
  description = "The email of the service account used by Argo Terraform apply workflow step instances."
  value       = module.ci_cd.terraform_apply_service_account_email
}

output "workflow_submitter_service_account_email" {
  description = "The email of the service account external callers should use to submit Argo deployment workflows."
  value       = module.ci_cd.workflow_submitter_service_account_email
}

output "backend_workload_identity" {
  description = "Google service account email used by backend Kubernetes workloads."
  value       = module.backend_service.service_account_email
}

output "backend_runtime_env_vars" {
  description = "Non-secret backend runtime environment variables."
  value       = module.backend_service.backend_runtime_env_vars
}

output "backend_service_backend_secret_refs" {
  description = "Secret Manager refs for backend runtime secrets."
  value       = module.backend_service.backend_secret_refs
}

output "backend_default_container_image_uri" {
  description = "Default backend image URI used by Terraform-managed Kubernetes resources."
  value       = module.backend_service.default_container_image_uri
}

output "backend_api_ip_name" {
  description = "Static regional IP name assigned to the ingress-nginx controller."
  value       = module.backend_service.ingress_nginx_ip_name
}

output "backend_api_ip_address" {
  description = "Static regional IP address assigned to the ingress-nginx controller."
  value       = module.backend_service.ingress_nginx_ip_address
}

output "database_instance_connection_name" {
  description = "Cloud SQL instance connection name used by backend Kubernetes workloads."
  value       = module.database.instance_connection_name
}

output "terraform_state_bucket_name" {
  description = "GCS bucket used for Terraform state and tfvars synchronization."
  value       = module.bucket_for_tf_state.bucket_name
}

output "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  value       = module.ci_cd.workflow_namespace
}

output "workflow_template_name" {
  description = "Name of the Argo deployment WorkflowTemplate."
  value       = module.ci_cd.workflow_template_name
}

output "workflow_kubernetes_service_accounts" {
  description = "Kubernetes service account names used by deployment workflow step instances."
  value       = module.ci_cd.workflow_kubernetes_service_accounts
}

output "workflow_step_service_account_emails" {
  description = "Google service account emails used by deployment workflow step service accounts."
  value = {
    terraform_apply   = module.ci_cd.terraform_apply_service_account_email
    source_inspector  = module.ci_cd.source_inspector_service_account_email
    backend_builder   = module.ci_cd.backend_builder_service_account_email
    frontend_deployer = module.ci_cd.frontend_deployer_service_account_email
    cdn_invalidator   = module.ci_cd.cdn_invalidator_service_account_email
  }
}

output "crucible_deployment_contract_version" {
  description = "The deployment contract version exposed to Crucible."
  value       = module.ci_cd.crucible_deployment_contract_version
}

output "workflow_required_parameters" {
  description = "Required parameters for submitting the Argo deployment workflow."
  value       = module.ci_cd.workflow_required_parameters
}

output "sentry_setup_instructions" {
  description = "Instructions for setting up Sentry auth token after first terraform apply."
  value       = <<-EOT
    ╔════════════════════════════════════════════════════════════════════════════╗
    ║                     SENTRY AUTH TOKEN SETUP REQUIRED                       ║
    ╚════════════════════════════════════════════════════════════════════════════╝

    The Sentry auth token secret has been created for future sourcemap upload
    support. The current Argo frontend build does not read this GCP Secret
    Manager secret directly, so an empty token does not block deployment.

    Steps to complete setup:

    1. Generate a Sentry auth token:
       - Go to https://sentry.io/settings/account/api/auth-tokens/
       - Click "Create New Token"
       - Give it a name like "${var.environment}-frontend-sourcemaps"
       - Select scopes: project:releases, project:write
       - Copy the generated token

    2. Add the token to Google Secret Manager:

       gcloud secrets versions add ${module.ci_cd.sentry_auth_token_secret_name} \
         --data-file=- \
         --project=${var.gcp_project_id} <<< "YOUR_SENTRY_AUTH_TOKEN"

    3. Verify the secret was added:

       gcloud secrets versions list ${module.ci_cd.sentry_auth_token_secret_name} \
         --project=${var.gcp_project_id}

    Secret Name: ${module.ci_cd.sentry_auth_token_secret_name}
    Secret ID: ${module.ci_cd.sentry_auth_token_secret_id}
  EOT
}
