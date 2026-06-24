variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used for frontend static website uploads."
  type        = string
}

variable "frontend_storage_account_name" {
  description = "Azure Storage account name that hosts the frontend static website."
  type        = string
}

variable "azure_cli_image" {
  description = "Azure CLI image used to upload frontend assets."
  type        = string
  default     = "mcr.microsoft.com/azure-cli:2.77.0"
}
