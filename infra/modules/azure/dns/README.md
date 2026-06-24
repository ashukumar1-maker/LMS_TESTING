# Azure DNS Module

Creates public DNS resources for Azure environments.

## Responsibilities

- Creates an Azure DNS zone for the environment domain.
- Enables DNSSEC for the Azure DNS zone.
- Creates the `api` A record pointing at the reserved backend public IP.

## Key Inputs

- `domain_name`: Public DNS zone name.
- `backend_ip_address`: Static backend IP created by `../network`.
- `resource_group_name`: Resource group where DNS resources live.

## Outputs

- `name_servers`: Azure nameservers to delegate from the parent domain.
- `ds_record_values`: DS record strings to configure at the parent domain for
  DNSSEC delegation.
- `dnssec_delegation_signer_info`: Structured DS record fields for registrars
  that ask for key tag, algorithm, digest type, and digest separately.
- `ds_record_instructions`: Human-readable parent-zone delegation instructions.

## Notes

DNSSEC is enabled through the Azure DNS `dnssecConfigs/default` child resource
because AzureRM does not currently expose DNSSEC settings on `azurerm_dns_zone`.
The DS record comes from the Azure-computed DNSSEC signing key response. The
parent domain still needs that generated DS record to complete the DNSSEC chain
of trust. Frontend custom-domain records will be added when the Azure
frontend/CDN path is completed.
