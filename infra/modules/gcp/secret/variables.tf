# ---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The GCP project ID where the secret will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "secret_name" {
  description = "The name of the secret (will be used to generate the secret ID)"
  type        = string
}

variable "initial_secret_value" {
  description = "The initial value of the secret"
  type        = string
  sensitive   = true
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "service_account_emails" {
  description = "List of service account emails that should have access to read this secret"
  type        = list(string)
  default     = []
}

variable "secret_prefix" {
  description = "Prefix for the secret ID (e.g., 'backend', 'api')"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels to apply to the secret"
  type        = map(string)
  default     = {}
}

variable "ignore_secret_changes" {
  description = "Whether to ignore changes to secret data after initial creation. Set to false for secrets that should update when their computed values change (e.g., DATABASE_URL)"
  type        = bool
  default     = true
}
