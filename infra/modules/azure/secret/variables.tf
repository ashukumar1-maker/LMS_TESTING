variable "key_vault_id" {
  description = "Azure Key Vault resource ID that will contain the secret."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "secret_name" {
  description = "Secret name. Underscores are converted to hyphens for Azure Key Vault."
  type        = string
}

variable "initial_secret_value" {
  description = "Initial secret value to write to Azure Key Vault."
  type        = string
  sensitive   = true
}

variable "secret_prefix" {
  description = "Optional prefix for the Key Vault secret name."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to the secret resource."
  type        = map(string)
  default     = {}
}

variable "ignore_secret_changes" {
  description = "Whether to ignore value changes after initial creation. Set false for computed secrets that should track Terraform changes."
  type        = bool
  default     = true
}
