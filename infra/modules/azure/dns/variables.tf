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

variable "domain_name" {
  description = "The public DNS zone name."
  type        = string
}

variable "backend_ip_address" {
  description = "Backend API public IP address."
  type        = string
}

variable "frontend_endpoint_id" {
  description = "Azure Front Door endpoint resource ID for the frontend apex domain."
  type        = string
}

variable "frontend_custom_domain_validation_token" {
  description = "Azure Front Door custom domain validation token for the frontend apex domain."
  type        = string
}
