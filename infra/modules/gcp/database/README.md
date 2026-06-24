# Database Module

This Terraform module provisions a secure, private Google Cloud SQL database instance with VPC connectivity. It's designed for production-ready deployments with built-in security features and environment-specific configurations.

## Features

* **Private-only access** - No public IP, accessible only within VPC
* **TLS enforcement** - Rejects unencrypted client connections
* **Automatic password generation** - Secure passwords generated if not provided
* **Environment-aware** - Deletion protection for production environments
* **VPC integration** - Full private connectivity via VPC peering
* **PostgreSQL optimized** - Defaults to PostgreSQL 15 with standard configuration

## Resources Created

1. **Google Project Services**
   * `sqladmin.googleapis.com` - Cloud SQL Admin API
   * `servicenetworking.googleapis.com` - Service Networking API

2. **Cloud SQL Instance** - Managed database instance with:
   * Private IP configuration only
   * Encrypted-only client connections
   * VPC network connectivity
   * Configurable machine type
   * Deletion protection (except in dev)

3. **Database** - Named database within the instance

4. **Database User** - Default user with secure password

5. **Random Password** - Auto-generated if not provided

## Usage

```hcl
module "database" {
  source = "./modules/gcp/database"

  gcp_project_id            = "your-gcp-project-id"
  region                    = "us-central1"
  environment               = "dev"
  is_dev                    = true
  
  # VPC configuration (required)
  vpc_network_id            = "projects/PROJECT/global/networks/NETWORK"
  private_ip_address_name   = "google-managed-services-vpc"
  vpc_peering_connection_id = "servicenetworking-googleapis-com"
  
  # Optional: Database configuration
  database_version          = "POSTGRES_15"  # or POSTGRES_14, POSTGRES_13, etc.
  tier                      = "db-custom-2-4096"  # For production workloads
  
  # Optional: Database name and credentials
  db_name                   = "myapp"
  db_user_name              = "app_user"
  db_user_password          = "secure-password-here"  # Omit for auto-generation
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `gcp_project_id` | The GCP project ID | string | - | yes |
| `region` | The GCP region for the database | string | - | yes |
| `environment` | Deployment environment (dev/staging/prod) | string | - | yes |
| `is_dev` | Whether this is a development environment | bool | - | yes |
| `vpc_network_id` | VPC network ID for private connectivity | string | - | yes |
| `private_ip_address_name` | Name of the private IP address allocation | string | - | yes |
| `vpc_peering_connection_id` | VPC peering connection ID | string | - | yes |
| `database_version` | Database engine version | string | `"POSTGRES_15"` | no |
| `tier` | Machine type for the database instance | string | `"db-f1-micro"` | no |
| `db_name` | Name of the database | string | `"default-db"` | no |
| `db_user_name` | Database username | string | `"default_user"` | no |
| `db_user_password` | Database password (auto-generated if null) | string | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_connection_name` | Cloud SQL instance connection name for socket connections |
| `public_ip_address` | Public IP address (always empty - private only) |
| `private_ip_address` | Private IP address of the database instance |
| `db_name` | Name of the created database |
| `db_user_name` | Database username |
| `db_user_password` | Database password (sensitive) |
| `db_host` | Database host IP address |
| `db_port` | Database port (5432 for PostgreSQL) |
| `database_uri` | Self-link URI of the database instance |

## Database Versions

The module supports various PostgreSQL versions. Common options:
* `POSTGRES_15` (default)
* `POSTGRES_14`
* `POSTGRES_13`
* `POSTGRES_12`

Check [Google Cloud SQL versions](https://cloud.google.com/sql/docs/postgres/db-versions) for the complete list.

## Machine Types (Tiers)

Common tier options:
* `db-f1-micro` - Shared core, 0.6 GB RAM (default, suitable for dev)
* `db-g1-small` - Shared core, 1.7 GB RAM
* `db-custom-1-3840` - 1 vCPU, 3.75 GB RAM
* `db-custom-2-4096` - 2 vCPU, 4 GB RAM
* `db-custom-4-8192` - 4 vCPU, 8 GB RAM

For production workloads, use dedicated CPU instances (`db-custom-*`).

## Network Configuration

The database requires existing VPC infrastructure:
1. A VPC network with private service connection
2. An allocated IP address range for Google services
3. A VPC peering connection to Google services

These are typically created by a VPC module and passed as inputs.

## Security Considerations

* **No Public IP** - Database is only accessible within the VPC
* **Encrypted Transport Required** - Instance enforces TLS for client connections
* **Password Security** - Auto-generated passwords are 16 characters with special characters
* **Deletion Protection** - Enabled by default for non-dev environments
* **Private Path** - Uses Google's private path for enhanced security
* **Sensitive Outputs** - Password output is marked as sensitive

## Connection Examples

### From Cloud Run

```bash
# Using Cloud SQL proxy (socket connection)
postgresql://USERNAME:PASSWORD@/DATABASE_NAME?host=/cloudsql/CONNECTION_NAME

# Direct private IP connection
postgresql://USERNAME:PASSWORD@PRIVATE_IP:5432/DATABASE_NAME
```

### From Compute Engine in same VPC

```bash
psql -h PRIVATE_IP -U USERNAME -d DATABASE_NAME
```

## Best Practices

1. **Use strong machine types for production** - Avoid shared-core instances
2. **Enable automated backups** - Add backup configuration for production
3. **Monitor connections** - Set up alerts for connection limits
4. **Use connection pooling** - Configure your application with connection pools
5. **Regular maintenance** - Schedule maintenance windows appropriately

## Limitations

* Only PostgreSQL is supported (port 5432 is hardcoded)
* No high availability configuration included
* No backup configuration in the base module
* No read replicas configuration
