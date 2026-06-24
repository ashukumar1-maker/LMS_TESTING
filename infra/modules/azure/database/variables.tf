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

variable "suffix" {
  description = "Short stable random suffix for globally unique names."
  type        = string
}

variable "virtual_network_id" {
  description = "Azure VNet ID."
  type        = string
}

variable "postgres_subnet_id" {
  description = "PostgreSQL delegated subnet ID."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
}

variable "sku_name" {
  description = "Azure PostgreSQL Flexible Server SKU."
  type        = string
}

variable "storage_mb" {
  description = "Azure PostgreSQL storage size in MB."
  type        = number
}
