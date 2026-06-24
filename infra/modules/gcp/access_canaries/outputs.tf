output "canary_secret_id" {
  description = "Canary Secret Manager secret ID."
  value       = module.canary_secret.secret_id
}

output "canary_bucket_name" {
  description = "Canary bucket name."
  value       = google_storage_bucket.canary.name
}

output "sensitive_db_enabled" {
  description = "Whether the sensitive canary DB is enabled in this environment."
  value       = !var.is_dev
}

output "sensitive_db_instance_name" {
  description = "Sensitive canary Cloud SQL instance name, null in dev."
  value       = var.is_dev ? null : google_sql_database_instance.sensitive_canary[0].name
}

output "sensitive_db_user_name" {
  description = "Sensitive canary Cloud SQL username, null in dev."
  value       = var.is_dev ? null : google_sql_user.sensitive_canary[0].name
}

output "sensitive_db_url" {
  description = "Sensitive canary database URL, null in dev."
  value       = local.sensitive_db_url
  sensitive   = true
}
