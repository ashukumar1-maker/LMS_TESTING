# ---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The GCP project ID where resources will be created."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the application."
  type        = string
}

variable "frontend_ip_address" {
  description = "The IP address of the frontend load balancer."
  type        = string
}

variable "backend_ip_address" {
  description = "The IP address of the backend load balancer."
  type        = string
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "description" {
  description = "Description for the managed zone."
  type        = string
  default     = ""
}

variable "enable_api_subdomain" {
  description = "Whether to create a DNS record for api.domain pointing to the backend."
  type        = bool
  default     = true
}

variable "enable_www_subdomain" {
  description = "Whether to create a DNS record for www.domain pointing to the root domain."
  type        = bool
  default     = true
}

variable "enable_dnssec" {
  description = "Whether to enable DNSSEC for the DNS zone."
  type        = bool
  default     = true
}
