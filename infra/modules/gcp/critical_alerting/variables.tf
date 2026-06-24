variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "critical_alert_emails" {
  description = "List of email recipients for critical Cloud Monitoring alerts"
  type        = list(string)
}

variable "critical_alert_phone_numbers" {
  description = "List of phone numbers (E.164 format) for critical Cloud Monitoring alerts"
  type        = list(string)
}

variable "arm_canaries" {
  description = "Whether the canary alert policies should be enabled."
  type        = bool
  default     = false
}

variable "canary_secret_id" {
  description = "Secret Manager canary secret ID."
  type        = string
}

variable "canary_bucket_name" {
  description = "GCS canary bucket name."
  type        = string
}

variable "sensitive_db_enabled" {
  description = "Whether the sensitive canary DB exists in this environment."
  type        = bool
  default     = false
}

variable "sensitive_db_instance_name" {
  description = "Sensitive canary Cloud SQL instance name, null when not enabled."
  type        = string
  default     = null
  nullable    = true
}

variable "sensitive_db_user_name" {
  description = "Sensitive canary Cloud SQL username, null when not enabled."
  type        = string
  default     = null
  nullable    = true
}
