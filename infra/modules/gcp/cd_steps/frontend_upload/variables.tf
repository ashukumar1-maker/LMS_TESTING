variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "frontend_bucket_name" {
  description = "Name of the GCS bucket that stores frontend assets."
  type        = string
}
