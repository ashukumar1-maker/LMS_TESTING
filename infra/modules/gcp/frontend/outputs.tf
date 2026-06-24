output "bucket_name" {
  description = "The name of the Storage bucket for static frontend."
  value       = google_storage_bucket.frontend.name
}

output "bucket_url" {
  description = "The URL of the Storage bucket (gs://)."
  value       = google_storage_bucket.frontend.url
}

output "cdn_ip_address" {
  description = "The IP address of the global forwarding rule (Cloud CDN endpoint)."
  value       = google_compute_global_forwarding_rule.frontend.ip_address
}

output "url_map_name" {
  description = "The name of the Compute URL map for the frontend CDN."
  value       = google_compute_url_map.frontend.name
}

output "frontend_url" {
  description = "The HTTP URL to access the static frontend site."
  value       = "http://${google_compute_global_forwarding_rule.frontend.ip_address}"
}

output "https_frontend_url" {
  description = "The HTTPS URL to access the static frontend site."
  value       = "https://${var.domain_name}"
}

output "load_balancer_ip_address" {
  description = "The IP address of the load balancer. Create an A record pointing your domain to this IP."
  value       = google_compute_global_forwarding_rule.frontend_https.ip_address # or .frontend if you prefer to output the HTTP one, they are the same.
}
