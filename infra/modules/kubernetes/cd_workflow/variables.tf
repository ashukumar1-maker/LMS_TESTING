variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "cloud" {
  description = "Cloud provider for provider-specific workflow behavior."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["gcp", "azure"], lower(var.cloud))
    error_message = "cloud must be one of: gcp, azure."
  }
}

variable "namespace" {
  description = "Namespace where Argo deployment workflows run."
  type        = string
  default     = "argo"
}

variable "workflow_template_name" {
  description = "Name of the Argo WorkflowTemplate."
  type        = string
  default     = "deploy-fullstack-template"
}

variable "backend_namespace" {
  description = "Namespace containing the backend Deployment."
  type        = string
}

variable "project_id" {
  description = "Ciridae project ID used by Terraform state sync."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID used by GCP-backed workflow steps. Required when cloud is gcp."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.gcp_project_id != null
    error_message = "gcp_project_id is required when cloud is gcp."
  }
}

variable "azure_subscription_id" {
  description = "Azure subscription ID used by Azure-backed workflow steps. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_subscription_id != null
    error_message = "azure_subscription_id is required when cloud is azure."
  }
}

variable "azure_tenant_id" {
  description = "Azure tenant ID used by Azure-backed workflow steps. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_tenant_id != null
    error_message = "azure_tenant_id is required when cloud is azure."
  }
}

variable "source_repository_url" {
  description = "HTTPS Git repository URL cloned by deployment workflows."
  type        = string
}

variable "backend_image_repository_uri" {
  description = "Backend image repository URI without a tag."
  type        = string
}

variable "backend_deployment_name" {
  description = "Backend Kubernetes Deployment name."
  type        = string
}

variable "backend_container_name" {
  description = "Backend container name inside the Deployment."
  type        = string
}

variable "backend_service_account_name" {
  description = "Kubernetes service account name used by backend runtime pods and deployment-time backend tasks."
  type        = string
}

variable "backend_env_config_map_name" {
  description = "ConfigMap name that contains backend non-secret runtime environment variables."
  type        = string
}

variable "backend_secret_name" {
  description = "Kubernetes Secret name that contains backend runtime secrets."
  type        = string
}

variable "cloud_sql_instance_connection_name" {
  description = "Cloud SQL instance connection name mounted through the Cloud SQL Auth Proxy sidecar."
  type        = string
}

variable "backend_storage_volume_mounts" {
  description = "Backend container volume mounts shared by runtime pods and deployment-time backend task pods."
  type = list(object({
    name       = string
    mount_path = string
  }))
}

variable "backend_storage_volumes" {
  description = "Backend pod volumes shared by runtime pods and deployment-time backend task pods."
  type = list(object({
    name        = string
    empty_dir   = bool
    csi_enabled = bool
    csi = object({
      driver            = string
      read_only         = bool
      volume_attributes = map(string)
    })
  }))
}

variable "backend_database_sidecar_containers" {
  description = "Backend database sidecar containers shared by runtime pods and deployment-time backend task pods."
  type = list(object({
    name              = string
    image             = string
    image_pull_policy = string
    args              = list(string)
    run_as_non_root   = bool
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
    volume_mounts = list(object({
      name       = string
      mount_path = string
    }))
  }))
}

variable "frontend_bucket_name" {
  description = "Frontend object storage bucket name."
  type        = string
}

variable "frontend_url_map_name" {
  description = "Frontend CDN cache target name. GCP uses a URL map; Azure uses a Front Door profile."
  type        = string
}

variable "frontend_cdn_endpoint_name" {
  description = "Azure Front Door endpoint name for frontend cache invalidation. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.frontend_cdn_endpoint_name != null
    error_message = "frontend_cdn_endpoint_name is required when cloud is azure."
  }
}

variable "frontend_domain_name" {
  description = "Frontend custom domain name used for Azure Front Door cache invalidation. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.frontend_domain_name != null
    error_message = "frontend_domain_name is required when cloud is azure."
  }
}

variable "azure_resource_group_name" {
  description = "Azure resource group containing the Front Door profile. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_resource_group_name != null
    error_message = "azure_resource_group_name is required when cloud is azure."
  }
}

variable "sentry_org" {
  description = "Sentry organization slug for frontend sourcemaps."
  type        = string
}

variable "sentry_project" {
  description = "Sentry project slug for frontend sourcemaps."
  type        = string
}

variable "identity_platform_api_key" {
  description = "Frontend Identity Platform API key."
  type        = string
}

variable "identity_platform_auth_domain" {
  description = "Frontend Identity Platform auth domain."
  type        = string
}

variable "identity_platform_project_id" {
  description = "Frontend Identity Platform project ID."
  type        = string
}

variable "identity_platform_storage_bucket" {
  description = "Frontend Identity Platform storage bucket."
  type        = string
}

variable "identity_platform_messaging_sender_id" {
  description = "Frontend Identity Platform messaging sender ID."
  type        = string
}

variable "identity_platform_app_id" {
  description = "Frontend Identity Platform app ID."
  type        = string
}

variable "auth_service_frontend_url" {
  description = "Frontend URL for the auth service."
  type        = string
}

variable "api_url" {
  description = "Backend API URL used by the frontend build."
  type        = string
}

variable "workflow_submitter_service_account_email" {
  description = "Cloud identity external callers use to submit Argo workflows. Required when cloud is gcp; optional for Azure until an external submitter identity is implemented."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.workflow_submitter_service_account_email != null
    error_message = "workflow_submitter_service_account_email is required when cloud is gcp."
  }
}

variable "workflow_kubernetes_service_accounts" {
  description = "Kubernetes service account names used by deployment workflow step instances."
  type        = map(string)
}

variable "workflow_step_service_account_emails" {
  description = "Cloud identity identifiers used by deployment workflow step service accounts. GCP uses service account emails; Azure uses managed identity client IDs."
  type        = map(string)
}

variable "workflow_state_config_map_name" {
  description = "ConfigMap used by the workflow to record successful hashes and digests. See README.md \"Workflow State ConfigMap\" for the data key schema."
  type        = string
  default     = "deployment-workflow-state"
}

variable "terraform_version" {
  description = "Terraform version installed by the workflow Terraform step instances."
  type        = string
  default     = "1.12.2"
}

variable "backend_cd_tasks" {
  description = "Ordered deployment-time backend tasks to run before backend rollout when the backend leg deploys a new image."
  type = list(object({
    name                     = string
    python_module            = string
    timeout_seconds          = number
    max_retries              = number
    ttl_seconds_after_finish = number
  }))

  validation {
    condition = alltrue([
      for task in var.backend_cd_tasks :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", task.name))
    ])
    error_message = "backend_cd_tasks[*].name must be a valid DNS label segment using lowercase letters, numbers, and hyphens."
  }
}
