output "bucket_name" {
  description = "The name of the bucket for tfstate."
  value       = google_storage_bucket.tfstate.name
}
