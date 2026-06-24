# ---------- REQUIRED CONFIGURATION ----------

variable "project_id" {
  description = "The Ciridae project ID"
  type        = string
}

variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy to."
  type        = string
}

variable "environment" {
  description = "The environment to deploy to."
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the application."
  type        = string
}

# ---------- IDENTITY PLATFORM CONFIGURATION ----------

variable "identity_platform_api_key" {
  description = "The API key for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_auth_domain" {
  description = "The auth domain for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_project_id" {
  description = "The project ID for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_storage_bucket" {
  description = "The storage bucket for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_messaging_sender_id" {
  description = "The messaging sender ID for the Identity Platform/Firebase."
  type        = string
}

variable "identity_platform_app_id" {
  description = "The app ID for the Identity Platform/Firebase."
  type        = string
}

variable "auth_service_frontend_url" {
  description = "The frontend URL for the auth service."
  type        = string
}

variable "auth_service_backend_url" {
  description = "The backend URL for the auth service."
  type        = string
}

# ---------- SENTRY CONFIGURATION ----------

variable "sentry_org" {
  description = "Sentry organization slug for frontend sourcemap uploads"
  type        = string
}

variable "sentry_project" {
  description = "Sentry project slug for frontend sourcemap uploads"
  type        = string
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
  default     = false
}

variable "backend_connector_subnetwork_cidr" {
  description = "CIDR range reserved for the future static backend egress subnet. Must be a /28."
  type        = string
  default     = "10.8.0.0/28"

  validation {
    condition     = can(cidrnetmask(var.backend_connector_subnetwork_cidr)) && can(regex("/28$", var.backend_connector_subnetwork_cidr))
    error_message = "backend_connector_subnetwork_cidr must be a valid IPv4 CIDR with a /28 mask (e.g. 10.8.0.0/28)."
  }
}

variable "backend_egress_static_ip_count" {
  description = "Number of regional static external IP addresses to reserve for backend Cloud NAT egress."
  type        = number
  default     = 1

  validation {
    condition     = var.backend_egress_static_ip_count >= 1 && floor(var.backend_egress_static_ip_count) == var.backend_egress_static_ip_count
    error_message = "backend_egress_static_ip_count must be an integer >= 1 to reserve at least one static IP for Cloud NAT egress."
  }
}

# ---------- ENVIRONMENT VARIABLES CONFIGURATION ----------

variable "backend_env_vars" {
  description = "Map of non-sensitive environment variables for the backend service"
  type        = map(string)
  default     = {}
}

variable "backend_secret_env_vars" {
  description = "Map of sensitive environment variables for the backend service (will be stored in Google Secret Manager)"
  type        = map(string)
  default     = {}
}

variable "frontend_env_vars" {
  description = "Map of environment variables for the frontend build (must start with VITE_)"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in keys(var.frontend_env_vars) :
      can(regex("^VITE_", key))
    ])
    error_message = "All frontend environment variable keys must start with 'VITE_'."
  }
}

variable "critical_alert_emails" {
  description = "List of email recipients for critical Cloud Monitoring alerts"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "critical_alert_phone_numbers" {
  description = "List of phone numbers (E.164 format) for critical Cloud Monitoring alerts"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "arm_canaries" {
  description = "Whether canary alerting and backend canary access should be enabled."
  type        = bool
  default     = false
}
