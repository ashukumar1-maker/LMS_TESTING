# VPC Module

This Terraform module creates a secure Virtual Private Cloud (VPC) network infrastructure on Google Cloud Platform with private service access for Cloud SQL and other managed services.

## Features

* **Custom VPC Network** - Isolated network with manual subnet control
* **Private Service Access** - Secure connectivity to Cloud SQL without public IPs
* **Environment Isolation** - Separate networks per environment
* **Security Controls** - Firewall rules with full logging
* **Private Google Access** - Access Google services without external IPs
* **Static Backend Egress** - Cloud NAT gateway using reserved regional IPs for backend public egress
* **Private GKE Node Egress** - Separate auto-allocated Cloud NAT for private GKE nodes
* **UUID Naming** - Prevents naming conflicts during deployments

## Resources Created

1. **Google APIs**:
   * Compute Engine API
   * Service Networking API

2. **VPC Network** - Custom network with:
   * Manual subnet creation mode
   * UUID suffix for unique naming
   * Lifecycle protection

3. **Subnet** - Regional subnet with:
   * Private Google Access enabled
   * Configurable IP CIDR range
   * Environment-based naming

4. **Reserved Backend Egress Subnet** - Dedicated `/28` subnet for the future static backend egress path.

5. **Cloud NAT Gateways**:
   * Regional Cloud Router
   * Deployment-provided reserved static external IP addresses
   * Manual NAT IP allocation for backend connector egress
   * Google-managed ephemeral NAT IP allocation for GKE node egress

6. **Private Service Access**:
   * Global address allocation (/16 range)
   * VPC peering connection for Cloud SQL

7. **Firewall Rules**:
   * PostgreSQL egress rule (port 5432)
   * Full metadata logging enabled

## Usage

```hcl
module "vpc" {
  source = "./modules/gcp/vpc"

  gcp_project_id = "your-gcp-project-id"
  region         = "us-central1"
  environment    = "dev"
  
  # Optional network configuration
  subnetwork_cidr                   = "10.0.0.0/24"
  backend_connector_subnetwork_cidr = "10.8.0.0/28"
  backend_egress_nat_ips = [
    "projects/PROJECT/regions/us-central1/addresses/dev-backend-egress-1"
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `gcp_project_id` | The GCP project ID | string | - | yes |
| `region` | Region for the subnet | string | - | yes |
| `environment` | Deployment environment | string | - | yes |
| `subnetwork_cidr` | IP CIDR range for subnet | string | `"10.0.0.0/24"` | no |
| `backend_connector_subnetwork_cidr` | `/28` CIDR range reserved for future static backend egress | string | - | yes |
| `backend_egress_nat_ips` | Reserved static external IP resources to use for backend Cloud NAT egress | list(string) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_network_id` | ID of the VPC network |
| `network_name` | Name of the VPC network |
| `network_self_link` | Self link of the VPC network |
| `private_ip_address_name` | Name of private IP allocation |
| `subnetwork_id` | ID of the subnet |
| `subnetwork_name` | Name of the subnet |
| `subnetwork_ip_cidr_range` | IP CIDR range of subnet |
| `subnetwork_self_link` | Self link of the subnet |
| `backend_connector_subnetwork_name` | Name of the backend connector subnet |
| `backend_connector_subnetwork_self_link` | Self link of the backend connector subnet |
| `peering_connection_id` | ID of VPC peering connection |

## Network Architecture

```
┌─────────────────────────────────────────────┐
│                VPC Network                  │
│                                             │
│    ┌─────────────────────────────────┐      │
│    │       Regional Subnet           │      │
│    │   CIDR: 10.0.0.0/24             │      │
│    │   Private Google Access: ON     │      │
│    └─────────────────────────────────┘      │
│                                             │
│    ┌─────────────────────────────────┐      │
│    │   Backend Connector Subnet      │      │
│    │   CIDR: 10.8.0.0/28             │      │
│    │   -> Cloud NAT static egress IPs│      │
│    └─────────────────────────────────┘      │
│                                             │
│    ┌─────────────────────────────────┐      │
│    │        GKE Node Subnet          │      │
│    │   CIDR: 10.2.0.0/24             │      │
│    │   -> Cloud NAT ephemeral egress │      │
│    └─────────────────────────────────┘      │
│                                             │
│    ┌─────────────────────────────────┐      │
│    │   Private Service Connection    │      │
│    │   CIDR: 192.168.0.0/16          │      │
│    │   → Cloud SQL VPC Peering       │      │
│    └─────────────────────────────────┘      │
└─────────────────────────────────────────────┘
```

## Private Service Access

The module sets up private connectivity for Google-managed services:

1. **IP Address Allocation**:
   * Reserves 192.168.0.0/16 for service connections
   * Provides 65,534 IP addresses for managed services

2. **VPC Peering**:
   * Establishes peering with `servicenetworking.googleapis.com`
   * Enables private Cloud SQL connections

3. **Benefits**:
   * No public IP exposure
   * Lower latency
   * Enhanced security
   * Reduced egress costs

## Static Backend Egress

The module keeps a reserved backend egress subnet and Cloud NAT gateway for the
future workload-specific static backend egress path. Cloud Run CD jobs no
longer use this path; deployment-time backend tasks now run through the Argo
workflow in the GKE cluster.

The backend NAT gateway is scoped to `backend_connector` with
`LIST_OF_SUBNETWORKS`. Other VPC subnets are not included in the backend NAT
configuration.

When using the deployment module, use this output when whitelisting backend egress on associated services:

```bash
terraform output -json backend_egress_static_ip_addresses
```

## Private GKE Node Egress

Private GKE nodes do not have public IP addresses, so the VPC default internet
route is not enough for public image pulls. The module creates a separate
Cloud Router and Cloud NAT for the GKE subnet with `AUTO_ONLY` IP allocation.
Google allocates ephemeral NAT IPs for this path; no static address is reserved
or exposed as an output.

This NAT exists for general cluster/node internet access, including public Helm
chart controller images. Do not treat it as the backend allowlisted egress
contract. Backend Kubernetes deployment egress through a stable static IP is
deferred to a workload-specific follow-up.

## Firewall Rules

### PostgreSQL Egress Rule
```
Direction: EGRESS
Protocol: TCP
Port: 5432
Destination: 192.168.0.0/16
Logging: INCLUDE_ALL_METADATA
```

This rule allows:
* Outbound PostgreSQL connections
* Only to the private service IP range
* Full audit logging for compliance

## Network Naming

The VPC network uses randomized naming:
```
Pattern: vpc-{environment}-{random-suffix}
Example: vpc-dev-a1b2c3d4
```

Prevents naming conflicts with previously deleted resources.

## Integration with Other Modules

### Database Module
```hcl
module "database" {
  vpc_network_id            = module.vpc.vpc_network_id
  private_ip_address_name   = module.vpc.private_ip_address_name
  vpc_peering_connection_id = module.vpc.peering_connection_id
  # ...
}
```

### CI/CD Module
```hcl
module "ci_cd" {
  vpc_network_id            = module.vpc.vpc_network_id
  vpc_peering_connection_id = module.vpc.peering_connection_id
  # ...
}
```

## Limitations

* Private service IP range is fixed at /16
* Single region deployment (no multi-region VPC)
