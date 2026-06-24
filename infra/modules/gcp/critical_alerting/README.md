# critical_alerting module

Creates critical monitoring/notification resources for a GCP project:

- Cloud Monitoring notification channels (email, optional SMS)
- Cloud Monitoring alert policies for Cloud SQL and HTTPS LB/CDN
- Cloud Monitoring log-based canary alert policies for Secret Manager reads, GCS object reads, and sensitive DB connection logs
- SCC notification config that streams high/critical active findings to Pub/Sub
- SCC Pub/Sub backlog alert policy that notifies configured email/SMS channels
- Project-level Data Access audit log enablement for Secret Manager and Cloud Storage

## API Activation

This module enables:

- `pubsub.googleapis.com`
- `monitoring.googleapis.com`

The parent deployment module must enable SCC APIs before invoking this module:

- `securitycenter.googleapis.com`
- `securitycentermanagement.googleapis.com`

## Alert Scope and Trigger Behavior

### Cloud SQL availability
- Policy: `google_monitoring_alert_policy.cloud_sql_availability`
- Trigger condition: `cloudsql.googleapis.com/database/up < 1` for `300s`
- Scope: all Cloud SQL instances in the project (no instance filter is applied)
- Important: because `trigger.count = 1`, one failing time series is enough to open the incident.

### HTTPS LB / CDN 5xx
- Policy: `google_monitoring_alert_policy.cdn_error_rate`
- Trigger condition: `COMPARISON_GT` on `loadbalancing.googleapis.com/https/request_count` filtered to `response_code_class="500"`, with `threshold_value = 5` and `duration = 300s`
- Aggregation details: `per_series_aligner = ALIGN_RATE` and `cross_series_reducer = REDUCE_SUM`
- Effective threshold expression: total HTTPS LB 5xx rate `> 5` requests/second sustained for 5 minutes (roughly more than 1500 5xx requests across 5 minutes)
- Threshold type: absolute 5xx request-rate threshold (not percentage-based)
- Scope: all matching HTTPS LB rule series in the project (no load balancer filter is applied)

### Security Command Center (SCC)
- Resource: `google_scc_v2_project_notification_config.critical_findings`
- Trigger condition: findings where `(severity="HIGH" OR severity="CRITICAL") AND state="ACTIVE"`
- Output path: publishes to Pub/Sub topic `scc-critical-findings-<environment>`
- Subscription path: `google_pubsub_subscription.scc_critical_findings_backlog` receives those events
- Human-facing notification path: `google_monitoring_alert_policy.scc_findings_pubsub_backlog` sends alerts to the module's email/SMS notification channels when backlog is greater than zero
- Important: this alert path is based on backlog presence (event arrival), not on per-finding payload routing. If richer per-finding formatting or workflow routing is required, add a dedicated subscriber (for example, Cloud Run or Cloud Function).

### Secret Manager canary read
- Policy: `google_monitoring_alert_policy.canary_secret_access`
- Trigger condition: Data Access audit log match on `AccessSecretVersion` for `canary_secret_id`
- Purpose: alert when the canary secret is read.
- Enabled only when `arm_canaries = true`.

### GCS canary object read
- Policy: `google_monitoring_alert_policy.canary_bucket_access`
- Trigger condition: Data Access audit log match on `storage.objects.get` for `canary_bucket_name`
- Purpose: alert when an object in the canary bucket is read.
- Enabled only when `arm_canaries = true`.

### Sensitive canary DB access (non-dev)
- Policy: `google_monitoring_alert_policy.canary_db_access`
- Trigger condition: Cloud SQL PostgreSQL log match for successful authentication of `sensitive_db_user_name` on `sensitive_db_instance_name`
- Enabled only when `arm_canaries = true`.
- Extracted labels included in notification docs:
  - `connection_time`
  - `source_ip`
  - `db_user`
  - `db_name`
  - `application_name`

## Inputs

- `gcp_project_id` (string)
- `environment` (string)
- `critical_alert_emails` (list(string))
- `critical_alert_phone_numbers` (list(string))
- `arm_canaries` (bool) — Enables the canary **alert policies** listed above only. 
- `canary_secret_id` (string)
- `canary_bucket_name` (string)
- `sensitive_db_enabled` (bool)
- `sensitive_db_instance_name` (string, nullable)
- `sensitive_db_user_name` (string, nullable)

## Output

- `notification_channel_ids`: channel IDs used by Monitoring alert policies.
