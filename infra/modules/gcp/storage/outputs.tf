output "bucket_name" {
  description = "The name of the created Google Cloud Storage bucket."
  value       = google_storage_bucket.default.name
}
