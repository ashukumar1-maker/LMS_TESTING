resource "google_monitoring_alert_policy" "canary_bucket_access" {
  project      = var.gcp_project_id
  display_name = "Critical: Canary bucket object read (${var.environment})"
  combiner     = "OR"
  enabled      = var.arm_canaries

  documentation {
    content = "Triggers when an object is read from the canary bucket."
  }

  conditions {
    display_name = "Canary bucket object read"

    condition_matched_log {
      filter = "log_id(\"cloudaudit.googleapis.com/data_access\") AND protoPayload.serviceName=\"storage.googleapis.com\" AND protoPayload.methodName=\"storage.objects.get\" AND resource.labels.bucket_name=\"${var.canary_bucket_name}\""
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
    google_project_iam_audit_config.storage_data_read,
  ]
}
