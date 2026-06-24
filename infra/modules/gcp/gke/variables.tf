variable "gcp_project_id" {
  description = "The GCP project ID where GKE resources will be created."
  type        = string
}

variable "region" {
  description = "The region for the GKE cluster."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
}

variable "network_self_link" {
  description = "Self link of the VPC network for GKE."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of the GKE subnetwork."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary range used for GKE pods."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range used for GKE services."
  type        = string
}

variable "master_authorized_networks" {
  description = "CIDR blocks authorized to access the private GKE control plane endpoint."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "node_machine_type" {
  description = "Machine type for the default GKE node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "node_disk_size_gb" {
  description = "Boot disk size for GKE nodes."
  type        = number
  default     = 50
}

variable "node_disk_type" {
  description = "Boot disk type for GKE nodes."
  type        = string
  default     = "pd-balanced"
}

variable "node_pool_initial_node_count" {
  description = "Initial node count per zone for non-dev managed node pools."
  type        = number
  default     = 1
}

variable "node_pool_min_node_count" {
  description = "Minimum node count per zone for non-dev autoscaling."
  type        = number
  default     = 1
}

variable "node_pool_max_node_count" {
  description = "Maximum node count per zone for non-dev autoscaling."
  type        = number
  default     = 24
}

variable "cluster_deletion_protection" {
  description = "Whether deletion protection is enabled for the GKE cluster."
  type        = bool
  default     = false
}

variable "backend_kubernetes_namespace" {
  description = "Namespace for future backend Kubernetes resources."
  type        = string
  default     = "backend"
}

variable "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for future backend workloads."
  type        = string
  default     = "backend"
}

variable "external_secrets_kubernetes_namespace" {
  description = "Namespace for the future External Secrets Operator."
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_kubernetes_service_account_name" {
  description = "Kubernetes service account name used by the future External Secrets Operator."
  type        = string
  default     = "external-secrets"
}
