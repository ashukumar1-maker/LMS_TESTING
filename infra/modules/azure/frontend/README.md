# Azure Frontend

Defines the Azure Front Door delivery layer for the static frontend.

## Responsibilities

- Enables Azure Storage static website hosting, which creates and manages the
  `$web` container for frontend build assets.
- Creates an Azure Front Door Standard profile and endpoint.
- Uses the Azure Storage static website endpoint as the Front Door origin.
- Attaches the root frontend domain as a Front Door custom domain with an Azure-managed certificate.
- Exposes the `$web` container ID used by frontend deployment RBAC.
- Exposes the Front Door profile and endpoint names used by CD cache invalidation.

## DNS Integration

The module emits the Front Door endpoint ID and custom-domain validation token.
`infra/modules/azure/dns` creates the apex alias record and `_dnsauth` TXT
record in the environment DNS zone.
