# ---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "project_id" {
  description = "The ID of the Ciridae project."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where resources will be created."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

variable "is_dev" {
  description = "Flag to indicate if this is a development environment."
  type        = bool
}

variable "frontend_url" {
  description = "The HTTPS URL of the frontend application. e.g. https://example.com"
  type        = string
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "bucket_name_suffix" {
  description = "Suffix for the bucket name, e.g., 'app-data'."
  type        = string
  default     = "app-data"
}

