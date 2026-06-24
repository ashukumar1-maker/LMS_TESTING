variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for canary resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
}
