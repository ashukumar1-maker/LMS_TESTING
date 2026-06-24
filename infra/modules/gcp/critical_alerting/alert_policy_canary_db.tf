locals {
  sensitive_canary_database_id = var.sensitive_db_instance_name == null ? null : "${var.gcp_project_id}:${var.sensitive_db_instance_name}"
}

resource "google_monitoring_alert_policy" "canary_db_access" {
  count = var.sensitive_db_enabled ? 1 : 0

  project      = var.gcp_project_id
  display_name = "Critical: Sensitive canary DB access (${var.environment})"
  combiner     = "OR"
  enabled      = var.arm_canaries

  documentation {
    content = <<-EOT
      Triggers when Cloud SQL PostgreSQL logs indicate a successful authentication to the sensitive canary DB user.

      Extracted details:
      - connection_time: $${log.extracted_label.connection_time}
      - source_ip: $${log.extracted_label.source_ip}
      - db_user: $${log.extracted_label.db_user}
      - db_name: $${log.extracted_label.db_name}
      - application_name: $${log.extracted_label.application_name}
    EOT
  }

  conditions {
    display_name = "Sensitive canary DB user authentication"

    condition_matched_log {
      filter = join(
        " AND ",
        [
          "resource.type=\"cloudsql_database\"",
          "log_id(\"cloudsql.googleapis.com/postgres.log\")",
          "resource.labels.database_id=\"${local.sensitive_canary_database_id}\"",
          "textPayload=~\"connection authenticated:\"",
          "textPayload=~\"${var.sensitive_db_user_name}\"",
        ]
      )

      label_extractors = {
        connection_time  = "REGEXP_EXTRACT(textPayload, \"^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:.+\\\\-]+)\")"
        source_ip        = "REGEXP_EXTRACT(textPayload, \"client=([^, ]+)\")"
        db_user          = "REGEXP_EXTRACT(textPayload, \"user=([^, ]+)\")"
        db_name          = "REGEXP_EXTRACT(textPayload, \"db=([^, ]+)\")"
        application_name = "REGEXP_EXTRACT(textPayload, \"app=([^, ]+)\")"
      }
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "14400s"
    }
  }

  notification_channels = local.critical_notification_channel_ids

  depends_on = [google_project_service.monitoring_api]
}
