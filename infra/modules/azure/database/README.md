# Azure Database Module

Creates the Azure PostgreSQL database substrate for backend runtime.

## Responsibilities

- Creates a private DNS zone for PostgreSQL Flexible Server.
- Links the private DNS zone to the application VNet.
- Creates Azure Database for PostgreSQL Flexible Server on a delegated subnet.
- Creates the application database.
- Generates the database administrator password.
- Exposes a PostgreSQL 17 `DATABASE_URL` using the server FQDN and SSL mode.

## Key Inputs

- `virtual_network_id`: VNet to link to PostgreSQL private DNS.
- `postgres_subnet_id`: Delegated subnet created by `../network`.
- `sku_name`, `storage_mb`: PostgreSQL capacity settings.
- `is_dev`: Controls backup retention and whether an Azure `CanNotDelete`
  management lock is applied to the PostgreSQL Flexible Server.
- `name_prefix`, `suffix`: Resource naming inputs from the deployment module.

## Outputs

- `database_name`: Application database name.
- `database_fqdn`: PostgreSQL Flexible Server FQDN.
- `database_url`: Sensitive PostgreSQL connection string stored by `../backend`
  in Key Vault.

## Notes

The database resource uses PostgreSQL version `17` and disables public network
access. PostgreSQL Flexible Server reaches the VNet through its delegated subnet
and private DNS zone, so this module does not create a separate Private Endpoint
resource. Both the PostgreSQL Flexible Server and application database use
`prevent_destroy = true` to block Terraform destroy. Non-dev environments also
apply an Azure `CanNotDelete` management lock on the server, matching GCP's
conditional `deletion_protection` behavior.
