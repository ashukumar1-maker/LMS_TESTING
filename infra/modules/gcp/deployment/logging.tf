locals {
  # Cloud Logging retention is configured in days.
  default_log_retention_days     = 30
  data_access_log_retention_days = 730
  # 7 years × 365 days.
  audit_log_retention_days = 2555

  audit_logs_bucket_base             = "audit-logs"
  data_access_audit_logs_bucket_base = "audit-data-access-logs"

  # Match Google Cloud and External audit logs.
  all_audit_log_filter = "(logName:\"cloudaudit.googleapis.com\" OR logName:\"externalaudit.googleapis.com\")"
  # Data Access logs get shorter retention than other audit categories.
  data_access_audit_log_filter = "(LOG_ID(\"cloudaudit.googleapis.com/data_access\") OR LOG_ID(\"externalaudit.googleapis.com/data_access\"))"
  # Sink filters use the Cloud Logging query language, audit logs expose the
  # service in protoPayload.serviceName, and the sample Storage audit entries in
  # this project include protoPayload.authorizationInfo.permission. The read
  # permissions below come from the Cloud Storage audit logging and IAM
  # permission docs. Docs:
  # - https://docs.cloud.google.com/logging/docs/view/logging-query-language
  # - https://docs.cloud.google.com/logging/docs/audit/understanding-audit-logs
  # - https://docs.cloud.google.com/storage/docs/audit-logging
  # - https://docs.cloud.google.com/storage/docs/access-control/iam-permissions
  storage_data_read_permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "storage.folders.get",
    "storage.folders.list",
    "storage.multipartUploads.list",
    "storage.multipartUploads.listParts",
  ]
  storage_read_permission_filter = join(
    " OR ",
    [
      for permission in local.storage_data_read_permissions :
      "protoPayload.authorizationInfo.permission=\"${permission}\""
    ],
  )
  storage_read_sink_exclusion_filter = "protoPayload.serviceName=\"storage.googleapis.com\" AND (${local.storage_read_permission_filter})"
  non_data_access_audit_filter       = "${local.all_audit_log_filter} AND NOT ${local.data_access_audit_log_filter}"
}

# Keep non-audit logs in the default project log bucket for 30 days.
resource "google_logging_project_bucket_config" "default_sink_bucket" {
  project        = var.gcp_project_id
  location       = "global"
  bucket_id      = "_Default"
  retention_days = local.default_log_retention_days
}

resource "random_id" "audit_logs_suffix" {
  byte_length = 2
  keepers = {
    project = var.gcp_project_id
    bucket  = local.audit_logs_bucket_base
  }
}

# Dedicated bucket for long-term (non-Data Access) audit log retention.
resource "google_logging_project_bucket_config" "audit_logs" {
  project        = var.gcp_project_id
  location       = "global"
  bucket_id      = "${local.audit_logs_bucket_base}-${random_id.audit_logs_suffix.hex}"
  retention_days = local.audit_log_retention_days
}

resource "random_id" "data_access_audit_logs_suffix" {
  byte_length = 2
  keepers = {
    project = var.gcp_project_id
    bucket  = local.data_access_audit_logs_bucket_base
  }
}

# Dedicated bucket for Data Access audit logs (2-year retention).
resource "google_logging_project_bucket_config" "data_access_audit_logs" {
  project        = var.gcp_project_id
  location       = "global"
  bucket_id      = "${local.data_access_audit_logs_bucket_base}-${random_id.data_access_audit_logs_suffix.hex}"
  retention_days = local.data_access_log_retention_days
}

# Route all non-Data Access audit logs to the 7-year audit bucket.
resource "google_logging_project_sink" "audit_logs" {
  project                = var.gcp_project_id
  name                   = "audit-logs-sink"
  destination            = "logging.googleapis.com/projects/${var.gcp_project_id}/locations/global/buckets/${google_logging_project_bucket_config.audit_logs.bucket_id}"
  unique_writer_identity = true

  filter = local.non_data_access_audit_filter
}

# Route Data Access audit logs to the 2-year audit bucket.
resource "google_logging_project_sink" "data_access_audit_logs" {
  project                = var.gcp_project_id
  name                   = "audit-data-access-sink"
  destination            = "logging.googleapis.com/projects/${var.gcp_project_id}/locations/global/buckets/${google_logging_project_bucket_config.data_access_audit_logs.bucket_id}"
  unique_writer_identity = true

  filter = local.data_access_audit_log_filter

  exclusions {
    name        = "exclude-storage-read-audit-logs"
    description = "Keep Cloud Storage read audit logs in _Default only."
    filter      = local.storage_read_sink_exclusion_filter
  }
}

# Note: We intentionally do not add a project-level exclusion to remove audit
# logs from _Default. Project exclusions apply to all sinks and would prevent
# audit logs from being routed to the dedicated audit buckets.
