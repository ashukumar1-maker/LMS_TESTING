output "name_servers" {
  description = "Azure DNS nameservers."
  value       = azurerm_dns_zone.default.name_servers
}

output "dnssec_delegation_signer_info" {
  description = "Structured DNSSEC DS record fields for parent-zone delegation."
  value       = local.dnssec_delegation_signer_info
}

output "ds_record_values" {
  description = "DNSSEC DS record values to configure at the parent DNS zone."
  value       = [for signer_info in local.dnssec_delegation_signer_info : signer_info.record]
}

output "ds_record_instructions" {
  description = "Instructions for adding DNSSEC DS records to the parent DNS zone."
  value = length(local.dnssec_delegation_signer_info) > 0 ? (
    "Add these DS records to the parent domain: ${join(", ", [for signer_info in local.dnssec_delegation_signer_info : signer_info.record])}"
  ) : null
}
