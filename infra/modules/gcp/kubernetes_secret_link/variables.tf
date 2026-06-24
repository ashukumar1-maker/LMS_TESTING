variable "gcp_project_id" {
  description = "GCP project ID containing Secret Manager secrets."
  type        = string
  nullable    = false
}

variable "namespace" {
  description = "Kubernetes namespace where the SecretStore and ExternalSecret are created."
  type        = string
}

variable "labels" {
  description = "Labels applied to Kubernetes resources."
  type        = map(string)
  default     = {}
}

variable "secret_store_labels" {
  description = "Labels applied to the Kubernetes SecretStore. Defaults to labels."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "secret_store_name" {
  description = "Kubernetes SecretStore name."
  type        = string
  default     = "google-secret-manager"
}

variable "external_secret_name" {
  description = "Kubernetes ExternalSecret name."
  type        = string
  default     = "backend-secrets"
}

variable "target_secret_name" {
  description = "Kubernetes Secret name created by External Secrets."
  type        = string
}

variable "secret_names" {
  description = "Map of Kubernetes Secret keys to Google Secret Manager secret names."
  type        = map(string)
}

variable "refresh_interval" {
  description = "External Secrets refresh interval."
  type        = string
  default     = "1h"
}
