variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used for ACR task runs."
  type        = string
}

variable "container_registry_login_server" {
  description = "Azure Container Registry login server."
  type        = string
}

variable "azure_cli_image" {
  description = "Azure CLI image used to submit ACR task runs."
  type        = string
  default     = "mcr.microsoft.com/azure-cli:2.77.0"
}
