output "name_servers" {
  description = "List of name servers for the managed zone. Configure these at the parent DNS provider for subdelegation."
  value       = google_dns_managed_zone.primary.name_servers
}

output "zone_id" {
  description = "The ID of the managed zone."
  value       = google_dns_managed_zone.primary.id
}

output "dns_name" {
  description = "DNS name of the managed zone (FQDN)."
  value       = google_dns_managed_zone.primary.dns_name
}

output "zone_name" {
  description = "The name of the DNS managed zone."
  value       = google_dns_managed_zone.primary.name
}

output "frontend_domain" {
  description = "The frontend domain (root domain)."
  value       = trimsuffix(google_dns_managed_zone.primary.dns_name, ".")
}

output "api_domain" {
  description = "The API subdomain."
  value       = var.enable_api_subdomain ? "api.${var.domain_name}" : null
}

output "www_domain" {
  description = "The www subdomain."
  value       = var.enable_www_subdomain ? "www.${var.domain_name}" : null
}

output "ds_record_values" {
  description = "DS record values for DNSSEC. Add these to your parent domain."
  value = var.enable_dnssec && length(data.google_dns_keys.dnssec_keys) > 0 ? [
    for key in data.google_dns_keys.dnssec_keys[0].key_signing_keys :
    "${key.ds_record}"
  ] : []
}

output "ds_record_instructions" {
  description = "Instructions for adding DS records to parent domain."
  value = var.enable_dnssec && length(data.google_dns_keys.dnssec_keys) > 0 ? (
    length(data.google_dns_keys.dnssec_keys[0].key_signing_keys) > 0 ?
    "Add this DS record to your parent domain: ${data.google_dns_keys.dnssec_keys[0].key_signing_keys[0].ds_record}" :
    "DNSSEC is enabled but DS records not yet available"
  ) : "DNSSEC is not enabled"
}
