variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "frontend_url_map_name" {
  description = "Compute URL map name for frontend CDN cache invalidation."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}
