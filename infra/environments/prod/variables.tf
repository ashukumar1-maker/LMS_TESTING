# ---------- REQUIRED CONFIGURATION ----------

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID"
  type        = string
}

variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the application"
  type        = string
}

variable "cloud" {
  description = "Cloud deployment implementation to use."
  type        = string
  default     = "gcp"

  validation {
    condition     = contains(["gcp"], lower(var.cloud))
    error_message = "cloud must be \"gcp\". Azure is reserved but is not implemented yet."
  }
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "source_repository_url" {
  description = "HTTPS Git repository URL cloned by deployment workflows."
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "is_dev" {
  description = "Whether the environment is development"
  type        = bool
  default     = false # Changed to false for production
}

# ---------- IDENTITY PLATFORM CONFIGURATION ----------

# DEFAULTS TO PROD AUTH

variable "identity_platform_api_key" {
  description = "The API key for the Identity Platform/Firebase"
  type        = string
  default     = "AIzaSyAdhUTwE_TuH38Ha0B0DLGO_VMfMxT7XjU"
}

variable "identity_platform_auth_domain" {
  description = "The auth domain for the Identity Platform/Firebase"
  type        = string
  default     = "int-auth-prod.firebaseapp.com"
}

variable "identity_platform_project_id" {
  description = "The project ID for the Identity Platform/Firebase"
  type        = string
  default     = "int-auth-prod"
}

variable "identity_platform_storage_bucket" {
  description = "The storage bucket for the Identity Platform/Firebase"
  type        = string
  default     = "int-auth-prod.firebasestorage.app"
}

variable "identity_platform_messaging_sender_id" {
  description = "The messaging sender ID for the Identity Platform/Firebase"
  type        = string
  default     = "1085960504992"
}

variable "identity_platform_app_id" {
  description = "The app ID for the Identity Platform/Firebase"
  type        = string
  default     = "1:1085960504992:web:0af8fb8af5806fbf0b2bc5"
}

variable "auth_service_frontend_url" {
  description = "The frontend URL for the auth service"
  type        = string
  default     = "https://auth.ciridae.app"
}

variable "auth_service_backend_url" {
  description = "The backend URL for the auth service"
  type        = string
  default     = "https://api.auth.ciridae.app"
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


variable "critical_alert_emails" {
  description = "Optional list of email recipients for critical Cloud Monitoring alerts"
  type        = list(string)
  default     = null
  nullable    = true
}

variable "critical_alert_phone_numbers" {
  description = "Optional list of phone numbers (E.164 format) for critical Cloud Monitoring alerts"
  type        = list(string)
  default     = null
  nullable    = true
}

variable "arm_canaries" {
  description = "Whether to arm canary alerting and backend canary access after bootstrap."
  type        = bool
  default     = false
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
}
