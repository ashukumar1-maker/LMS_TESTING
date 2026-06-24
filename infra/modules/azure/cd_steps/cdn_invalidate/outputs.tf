output "template" {
  description = "Argo Template object for the Azure CDN invalidation step."
  value       = local.invalidate_frontend_cache_step_template
}
