#---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The GCP project ID where resources will be provisioned."
  type        = string
}

variable "project_id" {
  description = "The ID of the Ciridae project."
  type        = string
}

variable "region" {
  description = "The region to create the storage bucket in."
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod). Used for resource naming."
  type        = string
}


variable "domain_name" {
  description = "The custom domain name for the frontend (e.g., www.example.com)."
  type        = string
}

#---------- OPTIONAL CONFIGURATION ----------

variable "main_page_suffix" {
  description = "The index document for the static website."
  type        = string
  default     = "index.html"
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket and all objects within it."
  type        = bool
  default     = true
}
