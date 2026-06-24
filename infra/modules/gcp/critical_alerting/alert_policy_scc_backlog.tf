resource "google_monitoring_alert_policy" "scc_findings_pubsub_backlog" {
  project      = var.gcp_project_id
  display_name = "Critical: SCC high/critical findings received (${var.environment})"
  combiner     = "OR"
  enabled      = true

  documentation {
    content = "Triggers when SCC high/critical ACTIVE findings are present in the SCC findings Pub/Sub subscription backlog."
  }

  conditions {
    display_name = "SCC findings Pub/Sub backlog > 0"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      threshold_value = 0
      filter          = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.label.\"subscription_id\"=\"${google_pubsub_subscription.scc_critical_findings_backlog.name}\""

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.critical_notification_channel_ids

  depends_on = [
    google_project_service.monitoring_api,
    google_pubsub_subscription.scc_critical_findings_backlog,
    google_scc_v2_project_notification_config.critical_findings,
  ]
}
