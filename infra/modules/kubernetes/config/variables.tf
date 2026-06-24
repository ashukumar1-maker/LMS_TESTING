variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "cloud" {
  description = "Cloud provider for cloud-specific Kubernetes resource options."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["gcp", "azure"], lower(var.cloud))
    error_message = "cloud must be one of: gcp, azure."
  }
}

variable "project_id" {
  description = "Ciridae project ID used by Terraform state sync."
  type        = string
}

variable "backend_namespace" {
  description = "Namespace for backend Kubernetes resources."
  type        = string
}

variable "backend_env_vars" {
  description = "Non-secret backend environment variables to expose through a ConfigMap."
  type        = map(string)
}

variable "backend_secret_refs" {
  description = "Cloud secret refs for backend secrets. These are exposed as secret names only, not values."
  type        = map(string)
}

variable "backend_config_map_name" {
  description = "Name of the backend environment ConfigMap."
  type        = string
  default     = "backend-env"
}

variable "backend_secret_refs_config_map_name" {
  description = "Name of the ConfigMap that contains Secret Manager secret refs for workload integrations."
  type        = string
  default     = "backend-secret-refs"
}

variable "service_account_name" {
  description = "Kubernetes service account name for backend workloads."
  type        = string
}

variable "backend_workload_identity" {
  description = "Cloud identity identifier used by backend Kubernetes workloads. GCP uses a service account email; Azure uses a managed identity client ID."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = contains(["gcp", "azure"], lower(var.cloud)) && var.backend_workload_identity != null
    error_message = "backend_workload_identity is required for supported clouds."
  }
}

variable "terraform_apply_service_account_email" {
  description = "Google service account email used by Terraform apply during bootstrap."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID containing Secret Manager secrets. Required when cloud is gcp."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.gcp_project_id != null
    error_message = "gcp_project_id is required when cloud is gcp."
  }
}

variable "azure_subscription_id" {
  description = "Azure subscription ID. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_subscription_id != null
    error_message = "azure_subscription_id is required when cloud is azure."
  }
}

variable "azure_key_vault_url" {
  description = "Azure Key Vault URL containing backend secrets. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_key_vault_url != null
    error_message = "azure_key_vault_url is required when cloud is azure."
  }
}

variable "azure_tenant_id" {
  description = "Azure tenant ID. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_tenant_id != null
    error_message = "azure_tenant_id is required when cloud is azure."
  }
}

variable "external_secrets_namespace" {
  description = "Namespace containing the External Secrets Operator service account. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.external_secrets_namespace != null
    error_message = "external_secrets_namespace is required when cloud is azure."
  }
}

variable "external_secrets_service_account_name" {
  description = "External Secrets Operator service account. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.external_secrets_service_account_name != null
    error_message = "external_secrets_service_account_name is required when cloud is azure."
  }
}

variable "domain_name" {
  description = "Base domain name. The API is exposed at api.<domain_name>."
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name used by the backend Ingress and cert-manager HTTP-01 solver."
  type        = string
  default     = "nginx"
}

variable "cert_manager_cluster_issuer_name" {
  description = "ClusterIssuer name used by backend Ingress TLS certificates."
  type        = string
  default     = "letsencrypt-prod"
}

variable "cert_manager_acme_server" {
  description = "ACME server URL used by cert-manager."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "cert_manager_acme_email" {
  description = "Optional ACME account email used by cert-manager for expiry and account notifications."
  type        = string
  default     = null
  nullable    = true
}

variable "ingress_tls_secret_name" {
  description = "Kubernetes Secret name where cert-manager stores the backend Ingress TLS certificate."
  type        = string
  default     = "backend-tls"
}

variable "cloud_sql_instance_connection_name" {
  description = "Cloud SQL instance connection name for the Cloud SQL Auth Proxy sidecar. Required when cloud is gcp."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.cloud_sql_instance_connection_name != null
    error_message = "cloud_sql_instance_connection_name is required when cloud is gcp."
  }
}

variable "gcs_bucket_name" {
  description = "GCS bucket mounted into the backend pods. Required when cloud is gcp."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "gcp" || var.gcs_bucket_name != null
    error_message = "gcs_bucket_name is required when cloud is gcp."
  }
}

variable "azure_storage_account_name" {
  description = "Azure Storage account name mounted into backend pods. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_storage_account_name != null
    error_message = "azure_storage_account_name is required when cloud is azure."
  }
}

variable "azure_storage_container_name" {
  description = "Azure Blob container name mounted into backend pods. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_storage_container_name != null
    error_message = "azure_storage_container_name is required when cloud is azure."
  }
}

variable "azure_storage_resource_group_name" {
  description = "Azure resource group containing the backend Storage account. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.azure_storage_resource_group_name != null
    error_message = "azure_storage_resource_group_name is required when cloud is azure."
  }
}

variable "image" {
  description = "Default backend image URI used before the first deployment build."
  type        = string
}

variable "workflow_namespace" {
  description = "Namespace where Argo deployment workflows run."
  type        = string
}

variable "workflow_template_name" {
  description = "Name of the Argo WorkflowTemplate."
  type        = string
}

variable "source_repository_url" {
  description = "HTTPS Git repository URL cloned by deployment workflows."
  type        = string
}

variable "frontend_bucket_name" {
  description = "Frontend object storage bucket name."
  type        = string
}

variable "frontend_url_map_name" {
  description = "Frontend CDN cache target name passed into the CD workflow. GCP uses a URL map; Azure uses a Front Door profile."
  type        = string
}

variable "frontend_cdn_endpoint_name" {
  description = "Azure Front Door endpoint name passed into the CD workflow for frontend cache invalidation. Required when cloud is azure."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = lower(var.cloud) != "azure" || var.frontend_cdn_endpoint_name != null
    error_message = "frontend_cdn_endpoint_name is required when cloud is azure."
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

variable "deployment_name" {
  description = "Backend Kubernetes Deployment name."
  type        = string
  default     = "backend"
}

variable "container_name" {
  description = "Backend application container name."
  type        = string
  default     = "backend"
}

variable "service_name" {
  description = "Backend Kubernetes Service name."
  type        = string
  default     = "backend"
}

variable "ingress_name" {
  description = "Backend Kubernetes Ingress name."
  type        = string
  default     = "backend"
}

variable "container_port" {
  description = "Backend container port."
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Backend health check path."
  type        = string
  default     = "/health"
}

variable "cpu_request" {
  description = "CPU request for the backend container."
  type        = string
  default     = "1000m"
}

variable "memory_request" {
  description = "Memory request for the backend container."
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the backend container."
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the backend container."
  type        = string
  default     = "512Mi"
}

variable "min_replicas" {
  description = "Minimum backend pod replicas."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum backend pod replicas."
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target average CPU utilization percentage for HPA."
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target average memory utilization percentage for HPA."
  type        = number
  default     = 80
}

variable "bucket_file_cache_size" {
  description = "GCS Fuse file cache size in MB. Null disables file cache options."
  type        = number
  default     = null
}

variable "cloud_sql_proxy_image" {
  description = "Cloud SQL Auth Proxy image."
  type        = string
  default     = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.15.2"
}
