# access_canaries module

Creates access canary resources that are intended to alert security contacts when touched:

- Secret Manager secret with a realistic-looking admin API key name and generated value
- GCS bucket + marker object with realistic-looking names
- Non-dev-only Cloud SQL public-IP canary database

## Behavior

- Secret and bucket canaries are created in every environment.
- The seeded bucket object is uploaded once via `local-exec` and is intentionally not tracked as a Terraform-managed GCS object, so later plans/applies do not refresh it from the bucket.
- The Cloud SQL canary is created only when `is_dev = false`.
- The Cloud SQL canary is intentionally internet-reachable (`0.0.0.0/0`) and cost-optimized:
  - `db-f1-micro`
  - `disk_size = 10` GB
  - `disk_type = PD_HDD`
- PostgreSQL connection logging flags are enabled to include connection details.

## Bootstrap Flow

- `arm_canaries` controls only whether Cloud Monitoring canary **alert policies** are enabled (see the `critical_alerting` module). 
- First apply with `arm_canaries = false` to create the secret, bucket, and seeded bucket object (and the non-dev Cloud SQL canary when applicable) without enabling canary alerts.
- Later apply with `arm_canaries = true` to enable the canary alert policies so touches are notified.
- Existing environments that already track `google_storage_bucket_object.canary_marker` in Terraform state need a one-time `terraform state rm module.deployment.module.access_canaries.google_storage_bucket_object.canary_marker` before the first apply after this change. Without that, Terraform will still refresh the old tracked object and plan to delete it.

## Outputs

- `canary_secret_id`
- `canary_bucket_name`
- `sensitive_db_enabled`
- `sensitive_db_instance_name`
- `sensitive_db_user_name`
- `sensitive_db_url` (sensitive)
