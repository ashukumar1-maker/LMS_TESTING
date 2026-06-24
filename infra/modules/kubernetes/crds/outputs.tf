output "external_secrets_namespace" {
  description = "Namespace for the External Secrets Operator."
  value       = kubernetes_namespace_v1.external_secrets.metadata[0].name
}

output "external_secrets_release_name" {
  description = "External Secrets Operator Helm release name."
  value       = helm_release.external_secrets.name
}

output "cert_manager_namespace" {
  description = "Namespace for cert-manager."
  value       = kubernetes_namespace_v1.cert_manager.metadata[0].name
}

output "cert_manager_release_name" {
  description = "cert-manager Helm release name."
  value       = helm_release.cert_manager.name
}

output "ingress_nginx_namespace" {
  description = "Namespace for ingress-nginx."
  value       = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
}

output "ingress_nginx_release_name" {
  description = "ingress-nginx Helm release name."
  value       = helm_release.ingress_nginx.name
}

output "argo_namespace" {
  description = "Namespace for Argo Workflows."
  value       = kubernetes_namespace_v1.argo.metadata[0].name
}

output "argo_workflows_release_name" {
  description = "Argo Workflows Helm release name."
  value       = helm_release.argo_workflows.name
}
