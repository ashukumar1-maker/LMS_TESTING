variable "key_vault_url" {
  description = "Azure Key Vault URL containing backend secrets."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "Azure tenant ID used by External Secrets Workload Identity auth."
  type        = string
  nullable    = false
}

variable "namespace" {
  description = "Kubernetes namespace where the ExternalSecret is created."
  type        = string
}

variable "external_secrets_namespace" {
  description = "Namespace containing the External Secrets Operator service account."
  type        = string
}

variable "external_secrets_service_account_name" {
  description = "External Secrets Operator service account used for Azure Workload Identity."
  type        = string
}

variable "labels" {
  description = "Labels applied to Kubernetes resources."
  type        = map(string)
  default     = {}
}

variable "secret_store_labels" {
  description = "Labels applied to the Kubernetes ClusterSecretStore. Defaults to labels."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "secret_store_name" {
  description = "Kubernetes ClusterSecretStore name."
  type        = string
  default     = "azure-key-vault"
}

variable "external_secret_name" {
  description = "Kubernetes ExternalSecret name."
  type        = string
  default     = "backend-secrets"
}

variable "target_secret_name" {
  description = "Kubernetes Secret name created by External Secrets."
  type        = string
}

variable "secret_names" {
  description = "Map of Kubernetes Secret keys to Azure Key Vault secret names."
  type        = map(string)
}

variable "refresh_interval" {
  description = "External Secrets refresh interval."
  type        = string
  default     = "1h"
}
