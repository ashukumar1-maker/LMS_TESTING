variable "azure_subscription_id" {
  description = "The Azure subscription ID."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "region" {
  description = "The Azure region for resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the application."
  type        = string
}

variable "identity_platform_api_key" {
  description = "The API key for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_auth_domain" {
  description = "The auth domain for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_project_id" {
  description = "The project ID for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_storage_bucket" {
  description = "The storage bucket for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_messaging_sender_id" {
  description = "The messaging sender ID for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_app_id" {
  description = "The app ID for the Identity Platform/Firebase."
  type        = string
}

variable "auth_service_frontend_url" {
  description = "The frontend URL for the auth service."
  type        = string
}

variable "auth_service_backend_url" {
  description = "The backend URL for the auth service."
  type        = string
}

variable "sentry_org" {
  description = "Sentry organization slug for frontend sourcemap uploads."
  type        = string
}

variable "sentry_project" {
  description = "Sentry project slug for frontend sourcemap uploads."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
  default     = false
}

variable "vnet_address_space" {
  description = "Address space for the Azure virtual network."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "CIDR range for AKS nodes."
  type        = string
  default     = "10.40.0.0/22"
}

variable "aks_api_server_subnet_cidr" {
  description = "CIDR range for the AKS API Server VNet Integration subnet."
  type        = string
  default     = "10.40.6.0/28"
}

variable "postgres_subnet_cidr" {
  description = "CIDR range for Azure PostgreSQL Flexible Server private access."
  type        = string
  default     = "10.40.4.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR range for Azure Private Endpoint resources."
  type        = string
  default     = "10.40.5.0/24"
}

variable "aks_node_count" {
  description = "Initial AKS node count."
  type        = number
  default     = 1
}

variable "aks_min_node_count" {
  description = "Minimum AKS autoscaler node count."
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum AKS autoscaler node count."
  type        = number
  default     = 4
}

variable "aks_node_vm_size" {
  description = "AKS default node pool VM size."
  type        = string
  default     = "Standard_D4as_v7"
}

variable "aks_public_cluster_enabled" {
  description = "Whether the AKS API server should be publicly reachable when the cluster is first created."
  type        = bool
  default     = false
}

variable "postgres_sku_name" {
  description = "Azure PostgreSQL Flexible Server SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Azure PostgreSQL storage size in MB."
  type        = number
  default     = 32768
}

variable "backend_env_vars" {
  description = "Map of non-sensitive environment variables for the backend service."
  type        = map(string)
  default     = {}
}

variable "backend_secret_env_vars" {
  description = "Map of sensitive environment variables for the backend service."
  type        = map(string)
  default     = {}
}

variable "frontend_env_vars" {
  description = "Map of environment variables for the frontend build."
  type        = map(string)
  default     = {}
}
