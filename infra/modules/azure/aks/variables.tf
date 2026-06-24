variable "resource_group_name" {
  description = "Azure resource group name."
  type        = string
}

variable "location" {
  description = "Azure resource location."
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for Azure resource names."
  type        = string
}

variable "dns_prefix" {
  description = "AKS DNS prefix."
  type        = string
}

variable "node_resource_group_name" {
  description = "Short Azure resource group name for AKS-managed node resources."
  type        = string
}

variable "aks_subnet_id" {
  description = "Subnet ID for AKS nodes."
  type        = string
}

variable "api_server_subnet_id" {
  description = "Delegated subnet ID for AKS API Server VNet Integration."
  type        = string
}

variable "control_plane_identity_id" {
  description = "User-assigned managed identity ID for the AKS control plane."
  type        = string
}

variable "public_cluster_enabled" {
  description = "Whether the AKS API server should be publicly reachable when the cluster is first created."
  type        = bool
  default     = false
}

variable "node_count" {
  description = "Initial AKS node count."
  type        = number
}

variable "min_node_count" {
  description = "Minimum AKS autoscaler node count."
  type        = number
}

variable "max_node_count" {
  description = "Maximum AKS autoscaler node count."
  type        = number
}

variable "node_vm_size" {
  description = "AKS default node pool VM size."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID used by the AKS Azure Monitor addon."
  type        = string
}
