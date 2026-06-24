variable "resource_group_name" {
  description = "Azure resource group name."
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

variable "suffix" {
  description = "Short unique suffix used to keep globally scoped Azure resource names unique."
  type        = string
}

variable "domain_name" {
  description = "Custom frontend domain name."
  type        = string
}

variable "storage_account_id" {
  description = "Azure Storage account ID that hosts the frontend static website."
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage account name that hosts the frontend static website."
  type        = string
}
