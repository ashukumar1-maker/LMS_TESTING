resource "google_monitoring_alert_policy" "cdn_error_rate" {
  project      = var.gcp_project_id
  display_name = "Critical: CDN / HTTPS LB 5xx error rate (${var.environment})"
  combiner     = "OR"
  enabled      = true

  documentation {
    content = "Triggers on sustained HTTPS LB 5xx responses, indicating frontend/CDN downtime risk."
  }

  conditions {
    display_name = "HTTPS LB 5xx responses"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "300s"
      threshold_value = 5
      filter          = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND metric.label.\"response_code_class\"=\"500\""

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.critical_notification_channel_ids

  depends_on = [google_project_service.monitoring_api]
}
