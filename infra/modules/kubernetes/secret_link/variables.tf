variable "cloud" {
  description = "Cloud provider used to select the secret link implementation."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["gcp", "azure"], lower(var.cloud))
    error_message = "cloud must be one of: gcp, azure."
  }
}

variable "gcp_project_id" {
  description = "GCP project ID containing Secret Manager secrets. Required when cloud is gcp."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.gcp_project_id != null
    error_message = "gcp_project_id is required when cloud is gcp."
  }
}

variable "azure_key_vault_url" {
  description = "Azure Key Vault URL containing backend secrets. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_key_vault_url != null
    error_message = "azure_key_vault_url is required when cloud is azure."
  }
}

variable "azure_tenant_id" {
  description = "Azure tenant ID. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_tenant_id != null
    error_message = "azure_tenant_id is required when cloud is azure."
  }
}

variable "namespace" {
  description = "Kubernetes namespace where the SecretStore and ExternalSecret are created."
  type        = string
}

variable "external_secrets_namespace" {
  description = "Namespace containing the External Secrets Operator service account. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.external_secrets_namespace != null
    error_message = "external_secrets_namespace is required when cloud is azure."
  }
}

variable "external_secrets_service_account_name" {
  description = "External Secrets Operator service account. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.external_secrets_service_account_name != null
    error_message = "external_secrets_service_account_name is required when cloud is azure."
  }
}

variable "labels" {
  description = "Labels applied to Kubernetes resources."
  type        = map(string)
  default     = {}
}

variable "secret_store_labels" {
  description = "Labels applied to the Kubernetes SecretStore. Defaults to labels."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "secret_store_name" {
  description = "Optional Kubernetes SecretStore name. Defaults to the provider-specific store name."
  type        = string
  default     = null
  nullable    = true
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
  description = "Map of Kubernetes Secret keys to cloud secret names."
  type        = map(string)
}

variable "refresh_interval" {
  description = "External Secrets refresh interval."
  type        = string
  default     = "1h"
}
