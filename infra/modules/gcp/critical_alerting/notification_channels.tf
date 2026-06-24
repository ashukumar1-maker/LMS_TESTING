resource "google_monitoring_notification_channel" "critical_email" {
  for_each = toset(var.critical_alert_emails)

  project      = var.gcp_project_id
  display_name = "Critical Alerts - ${var.environment} - ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }

  enabled = true

  depends_on = [google_project_service.monitoring_api]
}

resource "google_monitoring_notification_channel" "critical_sms" {
  for_each = toset(var.critical_alert_phone_numbers)

  project      = var.gcp_project_id
  display_name = "Critical Alerts SMS - ${var.environment} - ${each.value}"
  type         = "sms"

  labels = {
    number = each.value
  }

  enabled = true

  depends_on = [google_project_service.monitoring_api]
}
