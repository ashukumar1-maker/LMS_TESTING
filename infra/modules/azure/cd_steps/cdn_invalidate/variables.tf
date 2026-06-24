variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used for Front Door cache invalidation."
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group containing the Front Door profile."
  type        = string
}

variable "frontdoor_profile_name" {
  description = "Azure Front Door profile name."
  type        = string
}

variable "frontdoor_endpoint_name" {
  description = "Azure Front Door endpoint name."
  type        = string
}

variable "frontend_domain_name" {
  description = "Frontend custom domain served by Azure Front Door."
  type        = string
}

variable "azure_cli_image" {
  description = "Azure CLI image used to purge the Front Door cache."
  type        = string
  default     = "mcr.microsoft.com/azure-cli:2.77.0"
}
