# Azure Network Module

Creates the base Azure networking resources for Azure environments.

## Responsibilities

- Creates the application virtual network.
- Creates the AKS subnet.
- Creates the PostgreSQL delegated subnet for Flexible Server private access.
- Creates the dedicated subnet for Azure Private Endpoint resources.
- Reserves the static public IP intended for backend ingress.

## Key Inputs

- `vnet_address_space`: VNet CIDR ranges.
- `aks_subnet_cidr`: AKS node subnet range.
- `postgres_subnet_cidr`: PostgreSQL delegated subnet range.
- `private_endpoint_subnet_cidr`: Private Endpoint subnet range.
- `name_prefix`: Resource naming prefix from the deployment orchestrator.

## Outputs

- `virtual_network_id`, `virtual_network_name`: VNet identifiers for database
  and future networking modules.
- `aks_subnet_id`: Passed to the AKS module.
- `postgres_subnet_id`: Passed to the database module.
- `private_endpoint_subnet_id`: Passed to modules that create Private
  Endpoints, starting with Key Vault in `../backend`.
- `backend_public_ip_name`, `backend_public_ip_address`: Used by DNS and future
  ingress wiring.

## Notes

This module owns subnet allocation only. Private Endpoint resources stay with
the module that owns the target service so resource ownership remains clear.
Ingress controllers, NAT gateways, and firewall policy should be added as
separate modules when the Azure runtime path needs them.
