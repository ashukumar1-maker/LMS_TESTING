output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.default.name
}

output "cluster_location" {
  description = "AKS cluster location."
  value       = azurerm_kubernetes_cluster.default.location
}

output "cluster_id" {
  description = "AKS cluster ID."
  value       = azurerm_kubernetes_cluster.default.id
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = azurerm_kubernetes_cluster.default.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID."
  value       = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
}
