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
  description = "Whether the deployment is in development mode."
  type        = bool
}
