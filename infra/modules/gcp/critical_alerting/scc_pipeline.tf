resource "google_pubsub_topic" "scc_critical_findings" {
  project = var.gcp_project_id
  name    = "scc-critical-findings-${var.environment}"

  depends_on = [google_project_service.pubsub_api]
}

resource "google_pubsub_subscription" "scc_critical_findings_backlog" {
  project = var.gcp_project_id
  name    = "scc-critical-findings-${var.environment}-backlog"
  topic   = google_pubsub_topic.scc_critical_findings.id

  ack_deadline_seconds       = 20
  message_retention_duration = "600s"
  retain_acked_messages      = false

  expiration_policy {
    ttl = ""
  }

  depends_on = [google_project_service.pubsub_api]
}

resource "google_scc_v2_project_notification_config" "critical_findings" {
  project      = var.gcp_project_id
  location     = "global"
  config_id    = "critical-findings-${var.environment}"
  description  = "Send ACTIVE HIGH/CRITICAL SCC findings to Pub/Sub."
  pubsub_topic = google_pubsub_topic.scc_critical_findings.id

  streaming_config {
    filter = "(severity=\"HIGH\" OR severity=\"CRITICAL\") AND state=\"ACTIVE\""
  }
}
