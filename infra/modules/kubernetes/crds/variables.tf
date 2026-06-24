variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "cloud" {
  description = "Cloud provider for cloud-specific controller identity options."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["gcp", "azure"], lower(var.cloud))
    error_message = "cloud must be one of: gcp, azure."
  }
}

variable "external_secrets_namespace" {
  description = "Namespace for the External Secrets Operator."
  type        = string
}

variable "external_secrets_service_account_name" {
  description = "Kubernetes service account name used by the External Secrets Operator."
  type        = string
}

variable "external_secrets_workload_identity" {
  description = "Cloud identity identifier used by External Secrets Operator. GCP uses a service account email; Azure uses a managed identity client ID."
  type        = string
  nullable    = false
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version."
  type        = string
  default     = "0.15.1"
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager."
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.20.2"
}

variable "ingress_nginx_namespace" {
  description = "Namespace for ingress-nginx."
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version."
  type        = string
  default     = "4.15.1"
}

variable "ingress_nginx_load_balancer_ip" {
  description = "Static public IP address assigned to the ingress-nginx controller LoadBalancer service."
  type        = string
  nullable    = false
}

variable "ingress_nginx_service_annotations" {
  description = "Optional annotations for the ingress-nginx controller LoadBalancer service."
  type        = map(string)
  default     = {}
}

variable "argo_namespace" {
  description = "Namespace for Argo Workflows."
  type        = string
  default     = "argo"
}

variable "argo_workflows_chart_version" {
  description = "Argo Workflows Helm chart version."
  type        = string
  default     = "0.45.20"
}
