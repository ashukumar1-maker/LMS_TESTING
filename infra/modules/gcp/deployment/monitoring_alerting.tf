module "critical_alerting" {
  source = "../critical_alerting"

  gcp_project_id               = var.gcp_project_id
  environment                  = var.environment
  critical_alert_emails        = var.critical_alert_emails
  critical_alert_phone_numbers = var.critical_alert_phone_numbers
  arm_canaries                 = var.arm_canaries
  canary_secret_id             = module.access_canaries.canary_secret_id
  canary_bucket_name           = module.access_canaries.canary_bucket_name
  sensitive_db_enabled         = module.access_canaries.sensitive_db_enabled
  sensitive_db_instance_name   = module.access_canaries.sensitive_db_instance_name
  sensitive_db_user_name       = module.access_canaries.sensitive_db_user_name

  depends_on = [
    google_project_service.security_command_center_api,
    google_project_service.security_command_center_management_api,
  ]
}
