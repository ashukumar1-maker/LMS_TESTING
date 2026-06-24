#---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for backend platform resources."
  type        = string
}

variable "environment" {
  description = "The name of the environment."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
  default     = true
}

variable "database_connection_name" {
  description = "The full connection name of the Cloud SQL instance (e.g., project:region:instance)."
  type        = string
}

variable "db_name" {
  description = "The name of the database to connect to."
  type        = string
}

variable "db_user_name" {
  description = "The database user name."
  type        = string
}

variable "db_user_password" {
  description = "The database user password."
  type        = string
  sensitive   = true
}

variable "storage_bucket_name" {
  description = "The name of the storage bucket to use."
  type        = string
}

variable "workload_identity_pool" {
  description = "The GKE Workload Identity pool."
  type        = string
}

variable "backend_kubernetes_namespace" {
  description = "Namespace for backend Kubernetes resources."
  type        = string
}

variable "backend_kubernetes_service_account_name" {
  description = "Kubernetes service account name for backend workloads."
  type        = string
}

variable "external_secrets_service_account_email" {
  description = "Google service account email used by External Secrets Operator."
  type        = string
}

variable "auth_service_backend_url" {
  description = "The URL of the auth service backend."
  type        = string
}

#---------- OPTIONAL CONFIGURATION ----------

variable "default_container_name" {
  description = "The name of the container to deploy, within the Artifact Registry repository."
  type        = string
  default     = "backend"
}

variable "default_container_tag" {
  description = "The tag of the container to deploy, within the Artifact Registry repository."
  type        = string
  default     = "init"
}

variable "env_vars" {
  description = "Map of non-sensitive environment variables for the backend runtime."
  type        = map(string)
  default     = {}
}

variable "backend_secret_env_vars" {
  description = "Map of sensitive environment variables for the backend service (will be stored in Google Secret Manager)"
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Base domain name for the application (e.g., example.com). The API will be available at api.[domain_name]"
  type        = string
}

variable "bucket_file_cache_size" {
  description = <<-EOT
    The size of the file cache for the GCS Fuse connection to the bucket.
    The cache is stored in pod-local storage.
    If null, the file cache will be disabled.
  EOT
  type        = number
  default     = null
}
