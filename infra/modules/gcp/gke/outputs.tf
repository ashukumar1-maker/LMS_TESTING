output "cluster_name" {
  description = "The GKE cluster name."
  value       = google_container_cluster.default.name
}

output "cluster_location" {
  description = "The GKE cluster location."
  value       = google_container_cluster.default.location
}

output "cluster_id" {
  description = "The GKE cluster resource ID."
  value       = google_container_cluster.default.id
}

output "fleet_membership_name" {
  description = "The Fleet membership name."
  value       = google_gke_hub_membership.default.membership_id
}

output "connect_gateway_host" {
  description = "Connect Gateway host for Kubernetes and Helm providers."
  value       = "https://connectgateway.googleapis.com/v1/projects/${data.google_project.default.number}/locations/global/gkeMemberships/${google_gke_hub_membership.default.membership_id}"
}

output "workload_identity_pool" {
  description = "The Workload Identity pool for the cluster."
  value       = local.workload_identity_pool
}

output "node_service_account_email" {
  description = "Email of the GKE node service account."
  value       = google_service_account.node.email
}

output "external_secrets_service_account_email" {
  description = "Email of the External Secrets Google service account."
  value       = google_service_account.external_secrets.email
}

output "backend_kubernetes_namespace" {
  description = "Namespace for future backend Kubernetes resources."
  value       = var.backend_kubernetes_namespace
}

output "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for future backend workloads."
  value       = var.backend_kubernetes_service_account_name
}

output "external_secrets_kubernetes_namespace" {
  description = "Namespace for the future External Secrets Operator."
  value       = var.external_secrets_kubernetes_namespace
}

output "external_secrets_kubernetes_service_account_name" {
  description = "Kubernetes service account name used by the future External Secrets Operator."
  value       = var.external_secrets_kubernetes_service_account_name
}
