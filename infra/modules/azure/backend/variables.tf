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

variable "acr_name" {
  description = "Azure Container Registry name."
  type        = string
}

variable "default_container_name" {
  description = "Backend image repository name within the registry."
  type        = string
  default     = "backend"
}

variable "default_container_tag" {
  description = "Backend image tag used before the first deployment build."
  type        = string
  default     = "init"
}

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  type        = string
}

variable "backend_namespace" {
  description = "Backend Kubernetes namespace."
  type        = string
}

variable "backend_service_account_name" {
  description = "Backend Kubernetes service account name."
  type        = string
}

variable "external_secrets_namespace" {
  description = "External Secrets Kubernetes namespace."
  type        = string
}

variable "external_secrets_service_account_name" {
  description = "External Secrets Kubernetes service account name."
  type        = string
}

variable "storage_account_id" {
  description = "Azure Storage account ID used by backend runtime storage."
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage account name used by backend runtime storage."
  type        = string
}

variable "backend_container_name" {
  description = "Backend blob container name."
  type        = string
}

variable "key_vault_id" {
  description = "Azure Key Vault ID used by backend runtime secret integrations."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "auth_service_backend_url" {
  description = "Backend URL for the auth service."
  type        = string
}

variable "backend_env_vars" {
  description = "Non-sensitive backend environment variables."
  type        = map(string)
  default     = {}
}
