variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "storage_account_id" {
  description = "Azure Storage account ID."
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage account name used by backend runtime storage."
  type        = string
}
