module "cd_workflow" {
  source = "../cd_workflow"

  environment                              = var.environment
  cloud                                    = var.cloud
  namespace                                = var.workflow_namespace
  workflow_template_name                   = var.workflow_template_name
  source_repository_url                    = var.source_repository_url
  backend_namespace                        = local.backend_namespace
  project_id                               = var.project_id
  gcp_project_id                           = var.gcp_project_id
  azure_subscription_id                    = var.azure_subscription_id
  azure_tenant_id                          = var.azure_tenant_id
  backend_image_repository_uri             = trimsuffix(var.image, ":init")
  backend_deployment_name                  = kubernetes_deployment_v1.backend.metadata[0].name
  backend_container_name                   = var.container_name
  backend_service_account_name             = var.service_account_name
  backend_env_config_map_name              = kubernetes_config_map_v1.backend_env.metadata[0].name
  backend_secret_name                      = local.backend_secret_name
  cloud_sql_instance_connection_name       = var.cloud_sql_instance_connection_name
  backend_database_sidecar_containers      = local.backend_database_sidecar_containers
  backend_storage_volume_mounts            = local.backend_storage_volume_mounts
  backend_storage_volumes                  = local.backend_storage_volumes
  backend_cd_tasks                         = var.backend_cd_tasks
  frontend_bucket_name                     = var.frontend_bucket_name
  frontend_url_map_name                    = var.frontend_url_map_name
  frontend_cdn_endpoint_name               = var.frontend_cdn_endpoint_name
  frontend_domain_name                     = var.domain_name
  azure_resource_group_name                = var.azure_storage_resource_group_name
  sentry_org                               = var.sentry_org
  sentry_project                           = var.sentry_project
  identity_platform_api_key                = var.identity_platform_api_key
  identity_platform_auth_domain            = var.identity_platform_auth_domain
  identity_platform_project_id             = var.identity_platform_project_id
  identity_platform_storage_bucket         = var.identity_platform_storage_bucket
  identity_platform_messaging_sender_id    = var.identity_platform_messaging_sender_id
  identity_platform_app_id                 = var.identity_platform_app_id
  auth_service_frontend_url                = var.auth_service_frontend_url
  api_url                                  = var.api_url
  workflow_submitter_service_account_email = var.workflow_submitter_service_account_email
  workflow_kubernetes_service_accounts     = var.workflow_kubernetes_service_accounts
  workflow_step_service_account_emails     = var.workflow_step_service_account_emails

  providers = {
    kubernetes = kubernetes
  }
}
