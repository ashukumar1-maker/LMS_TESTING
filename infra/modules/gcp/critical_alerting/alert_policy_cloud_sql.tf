resource "google_monitoring_alert_policy" "cloud_sql_availability" {
  project      = var.gcp_project_id
  display_name = "Critical: Cloud SQL availability (${var.environment})"
  combiner     = "OR"
  enabled      = true

  documentation {
    content = "Triggers when Cloud SQL availability drops, indicating possible DB downtime."
  }

  conditions {
    display_name = "Cloud SQL up metric below 1"

    condition_threshold {
      comparison      = "COMPARISON_LT"
      duration        = "300s"
      threshold_value = 1
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/up\""

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.critical_notification_channel_ids

  depends_on = [google_project_service.monitoring_api]
}
