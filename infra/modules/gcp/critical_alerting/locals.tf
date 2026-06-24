locals {
  critical_notification_channel_ids = concat(
    values(google_monitoring_notification_channel.critical_email)[*].name,
    values(google_monitoring_notification_channel.critical_sms)[*].name,
  )
}
