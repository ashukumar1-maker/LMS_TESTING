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

variable "vnet_address_space" {
  description = "Address space for the Azure virtual network."
  type        = list(string)
}

variable "aks_subnet_cidr" {
  description = "CIDR range for AKS nodes."
  type        = string
}

variable "api_server_subnet_cidr" {
  description = "CIDR range for the AKS API Server VNet Integration subnet."
  type        = string
}

variable "postgres_subnet_cidr" {
  description = "CIDR range for Azure PostgreSQL Flexible Server private access."
  type        = string
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR range for Azure Private Endpoint resources."
  type        = string
}
