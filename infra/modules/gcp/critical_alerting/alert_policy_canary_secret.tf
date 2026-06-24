resource "google_monitoring_alert_policy" "canary_secret_access" {
  project      = var.gcp_project_id
  display_name = "Critical: Canary secret read (${var.environment})"
  combiner     = "OR"
  enabled      = var.arm_canaries

  documentation {
    content = "Triggers when the canary Secret Manager secret is read."
  }

  conditions {
    display_name = "Canary secret read"

    condition_matched_log {
      filter = "log_id(\"cloudaudit.googleapis.com/data_access\") AND protoPayload.serviceName=\"secretmanager.googleapis.com\" AND protoPayload.methodName=\"google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion\" AND protoPayload.resourceName=~\"projects/.*/secrets/${var.canary_secret_id}/versions/.*\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "14400s"
    }
  }

  notification_channels = local.critical_notification_channel_ids

  depends_on = [
    google_project_service.monitoring_api,
    google_project_iam_audit_config.secretmanager_data_read,
  ]
}
