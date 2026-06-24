variable "gcp_project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "project_id" {
  description = "The Ciridae project ID."
  type        = string
}

variable "region" {
  description = "The region for deployment orchestration resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment name."
  type        = string
}

variable "frontend_bucket_name" {
  description = "Name of the frontend storage bucket to grant Argo workflow uploads."
  type        = string
}

variable "frontend_url_map_name" {
  description = "The Compute URL map name for frontend CDN cache invalidation."
  type        = string
}

variable "tf_state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state and tfvars storage."
  type        = string
}

variable "workload_identity_pool" {
  description = "GKE Workload Identity pool, for example project-id.svc.id.goog."
  type        = string
}

variable "workflow_namespace" {
  description = "Namespace where Argo Workflows and deployment workflow step instances run."
  type        = string
  default     = "argo"
}

variable "workflow_template_name" {
  description = "Name of the deployment WorkflowTemplate."
  type        = string
  default     = "deploy-fullstack-template"
}

variable "sentry_org" {
  description = "Sentry organization slug for frontend sourcemap uploads."
  type        = string
}

variable "sentry_project" {
  description = "Sentry project slug for frontend sourcemap uploads."
  type        = string
}
