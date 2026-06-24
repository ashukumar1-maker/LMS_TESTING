# DNS Module

Creates the Cloud DNS managed zone and application records.

## Records

- Root domain `A` record points at the frontend load balancer IP.
- Optional `www` CNAME points at the root domain.
- Optional `api` `A` record points at the backend API static IP, which is used
  by the Kubernetes ingress.

## Inputs

- `gcp_project_id`
- `environment`
- `domain_name`
- `frontend_ip_address`
- `backend_ip_address`
- `description`
- `enable_api_subdomain`
- `enable_www_subdomain`
- `enable_dnssec`

## Outputs

- `name_servers`
- `zone_id`
- `dns_name`
- `zone_name`
- `frontend_domain`
- `api_domain`
- `www_domain`
- `ds_record_values`
- `ds_record_instructions`

DNSSEC DS records still need to be added at the parent registrar when DNSSEC is
enabled.
