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

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  type        = string
}

variable "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  type        = string
}

variable "resource_group_id" {
  description = "Azure resource group ID."
  type        = string
}

variable "storage_account_id" {
  description = "Azure Storage account ID."
  type        = string
}

variable "frontend_static_website_container_id" {
  description = "Azure Blob container ID for static website frontend assets."
  type        = string
}

variable "container_registry_id" {
  description = "Azure Container Registry ID."
  type        = string
}

variable "sentry_auth_token_secret_id" {
  description = "Azure Key Vault secret ID for the Sentry auth token."
  type        = string
}
