terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.47" # Match version constraint for consistency
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "google" {
  project               = var.gcp_project_id
  billing_project       = var.gcp_project_id
  region                = var.region
  user_project_override = true
  # You might need to configure region or other provider settings here
}

provider "google-beta" {
  alias                 = "google-beta"
  project               = var.gcp_project_id
  billing_project       = var.gcp_project_id
  region                = var.region
  user_project_override = true
}

provider "kubernetes" {
  host = module.deployment.gke_connect_gateway_host

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  kubernetes {
    host = module.deployment.gke_connect_gateway_host

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

module "deployment" {
  source = "../../modules/gcp/deployment"

  gcp_project_id = var.gcp_project_id
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  is_dev         = var.is_dev
  domain_name    = var.domain_name

  # Identity Platform Configuration
  identity_platform_api_key             = var.identity_platform_api_key
  identity_platform_auth_domain         = var.identity_platform_auth_domain
  identity_platform_project_id          = var.identity_platform_project_id
  identity_platform_storage_bucket      = var.identity_platform_storage_bucket
  identity_platform_messaging_sender_id = var.identity_platform_messaging_sender_id
  identity_platform_app_id              = var.identity_platform_app_id
  auth_service_frontend_url             = var.auth_service_frontend_url
  auth_service_backend_url              = var.auth_service_backend_url

  # Sentry Configuration
  sentry_org     = var.sentry_org
  sentry_project = var.sentry_project

  # Environment variables
  backend_env_vars        = var.backend_env_vars
  backend_secret_env_vars = var.backend_secret_env_vars
  frontend_env_vars       = var.frontend_env_vars

  # Critical alerting configuration
  critical_alert_emails        = var.critical_alert_emails
  critical_alert_phone_numbers = var.critical_alert_phone_numbers
  arm_canaries                 = var.arm_canaries

  providers = {
    google      = google
    google-beta = google-beta
  }
}

module "kubernetes_crds" {
  source = "../../modules/kubernetes/crds"

  environment                           = var.environment
  cloud                                 = "gcp"
  external_secrets_namespace            = module.deployment.external_secrets_kubernetes_namespace
  external_secrets_service_account_name = module.deployment.external_secrets_kubernetes_service_account_name
  external_secrets_workload_identity    = module.deployment.external_secrets_workload_identity
  argo_namespace                        = module.deployment.workflow_namespace
  ingress_nginx_load_balancer_ip        = module.deployment.backend_api_ip_address

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "kubernetes_config" {
  source = "../../modules/kubernetes/config"

  cloud                                    = "gcp"
  environment                              = var.environment
  source_repository_url                    = var.source_repository_url
  backend_namespace                        = module.deployment.backend_kubernetes_namespace
  backend_env_vars                         = module.deployment.backend_runtime_env_vars
  backend_secret_refs                      = module.deployment.backend_service_backend_secret_refs
  service_account_name                     = module.deployment.backend_kubernetes_service_account_name
  backend_workload_identity                = module.deployment.backend_workload_identity
  terraform_apply_service_account_email    = module.deployment.terraform_apply_service_account_email
  gcp_project_id                           = var.gcp_project_id
  domain_name                              = var.domain_name
  cloud_sql_instance_connection_name       = module.deployment.database_instance_connection_name
  gcs_bucket_name                          = module.deployment.backend_runtime_env_vars["MOUNTED_BACKEND_GCS_BUCKET_NAME"]
  image                                    = module.deployment.backend_default_container_image_uri
  workflow_namespace                       = module.kubernetes_crds.argo_namespace
  workflow_template_name                   = module.deployment.workflow_template_name
  project_id                               = var.project_id
  frontend_bucket_name                     = module.deployment.frontend_bucket_name
  frontend_url_map_name                    = module.deployment.frontend_url_map_name
  sentry_org                               = var.sentry_org
  sentry_project                           = var.sentry_project
  identity_platform_api_key                = var.identity_platform_api_key
  identity_platform_auth_domain            = var.identity_platform_auth_domain
  identity_platform_project_id             = var.identity_platform_project_id
  identity_platform_storage_bucket         = var.identity_platform_storage_bucket
  identity_platform_messaging_sender_id    = var.identity_platform_messaging_sender_id
  identity_platform_app_id                 = var.identity_platform_app_id
  auth_service_frontend_url                = var.auth_service_frontend_url
  api_url                                  = module.deployment.api_url
  workflow_submitter_service_account_email = module.deployment.workflow_submitter_service_account_email
  workflow_kubernetes_service_accounts     = module.deployment.workflow_kubernetes_service_accounts
  workflow_step_service_account_emails     = module.deployment.workflow_step_service_account_emails
  backend_cd_tasks = [
    {
      name                     = "migrations"
      python_module            = "src.cd_tasks.run_alembic_migrations"
      timeout_seconds          = 600
      max_retries              = 0
      ttl_seconds_after_finish = 86400
    }
  ]

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    module.deployment,
    module.kubernetes_crds,
  ]
}
