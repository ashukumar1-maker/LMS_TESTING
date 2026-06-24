variable "step_service_account_name" {
  description = "Kubernetes service account name used by this Argo step."
  type        = string
}

variable "kaniko_image" {
  description = "Kaniko image used for backend container builds and Artifact Registry pushes."
  type        = string
  default     = "gcr.io/kaniko-project/executor:v1.23.2"
}
