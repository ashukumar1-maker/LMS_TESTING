module "gcp_build_and_push_backend_image_step" {
  count = local.cloud == "gcp" ? 1 : 0

  source = "../../gcp/cd_steps/build_and_push_backend_image_step"

  step_service_account_name = kubernetes_service_account_v1.step_instances["backend_builder"].metadata[0].name
}

module "gcp_frontend_upload_step" {
  count = local.cloud == "gcp" ? 1 : 0

  source = "../../gcp/cd_steps/frontend_upload"

  step_service_account_name = kubernetes_service_account_v1.step_instances["frontend_deployer"].metadata[0].name
  frontend_bucket_name      = var.frontend_bucket_name
}

module "gcp_cdn_invalidate_step" {
  count = local.cloud == "gcp" ? 1 : 0

  source = "../../gcp/cd_steps/cdn_invalidate"

  step_service_account_name = kubernetes_service_account_v1.step_instances["cdn_invalidator"].metadata[0].name
  frontend_url_map_name     = var.frontend_url_map_name
  gcp_project_id            = var.gcp_project_id
}

module "azure_build_and_push_backend_image_step" {
  count = local.cloud == "azure" ? 1 : 0

  source = "../../azure/cd_steps/build_and_push_backend_image_step"

  step_service_account_name       = kubernetes_service_account_v1.step_instances["backend_builder"].metadata[0].name
  azure_subscription_id           = var.azure_subscription_id
  container_registry_login_server = split("/", var.backend_image_repository_uri)[0]
}

module "azure_frontend_upload_step" {
  count = local.cloud == "azure" ? 1 : 0

  source = "../../azure/cd_steps/frontend_upload"

  step_service_account_name     = kubernetes_service_account_v1.step_instances["frontend_deployer"].metadata[0].name
  azure_subscription_id         = var.azure_subscription_id
  frontend_storage_account_name = var.frontend_bucket_name
}

module "azure_cdn_invalidate_step" {
  count = local.cloud == "azure" ? 1 : 0

  source = "../../azure/cd_steps/cdn_invalidate"

  step_service_account_name = kubernetes_service_account_v1.step_instances["cdn_invalidator"].metadata[0].name
  azure_subscription_id     = var.azure_subscription_id
  resource_group_name       = var.azure_resource_group_name
  frontdoor_profile_name    = var.frontend_url_map_name
  frontdoor_endpoint_name   = var.frontend_cdn_endpoint_name
  frontend_domain_name      = var.frontend_domain_name
}

locals {
  # `var.cloud` is validated to either gcp or azure, so each concat below has
  # exactly one template. Avoid conditional object selection here: GCP and Azure
  # Argo templates intentionally have different shapes, and Terraform requires
  # conditional branches to have matching object types.
  build_and_push_backend_image_step_template = concat(
    [for step in module.gcp_build_and_push_backend_image_step : step.template],
    [for step in module.azure_build_and_push_backend_image_step : step.template],
  )[0]
  upload_frontend_assets_step_template = concat(
    [for step in module.gcp_frontend_upload_step : step.template],
    [for step in module.azure_frontend_upload_step : step.template],
  )[0]
  invalidate_frontend_cache_step_template = concat(
    [for step in module.gcp_cdn_invalidate_step : step.template],
    [for step in module.azure_cdn_invalidate_step : step.template],
  )[0]
}
