# GCP Deployment Module

This Terraform module orchestrates the deployment of a complete full-stack application infrastructure on Google Cloud Platform. GCP environment roots source this module directly as `module "deployment"` so GCP roots only require GCP providers.

## Overview

The deployment module creates a production-ready infrastructure stack including:
* VPC networking with private connectivity
* GKE cluster infrastructure for the backend Kubernetes runtime
* Protected static backend public egress IPs passed into Cloud NAT
* Auto-allocated Cloud NAT egress for private GKE node internet access
* Cloud SQL database with VPC peering
* Cloud Storage buckets for file storage
* Backend platform resources for Kubernetes and Argo backend CD tasks
* Frontend hosting with CDN and load balancing
* Argo deployment workflow identities, secrets, and contract outputs
* Custom domain with DNS and DNSSEC


## Child Modules

1. **VPC** - Creates network infrastructure
2. **GKE** - Creates the private, VPC-native GKE cluster, node pool, Fleet membership, and Connect Gateway outputs
3. **Database** - Provisions Cloud SQL with private connectivity
4. **Storage** - Creates GCS buckets for backend storage
5. **Backend** - Creates backend Artifact Registry, service account, secrets, and the reserved API IP for ingress-nginx
6. **Frontend** - Sets up static hosting with CDN
7. **Deployment Workflow** - Configures Argo workflow task identities, Sentry secret, and contract outputs
8. **DNS** - Manages domain and DNSSEC configuration
9. **Access Canaries** - Provisions secret, bucket, and non-dev sensitive DB canaries

## Usage

```hcl
module "deployment" {
  source = "./modules/gcp/deployment"

  # Project configuration
  project_id     = "your-ciridae-project-id"
  gcp_project_id = "your-gcp-project-id"
  region         = "us-central1"
  environment    = "dev"
  is_dev         = true

  # Backend egress
  backend_connector_subnetwork_cidr = "10.8.0.0/28"
  backend_egress_static_ip_count    = 1
  
  # Domain configuration
  domain_name = "yourdomain.com"
  
  # Identity Platform / Firebase configuration
  identity_platform_api_key              = "your-api-key"
  identity_platform_auth_domain          = "your-project.firebaseapp.com"
  identity_platform_project_id           = "your-project"
  identity_platform_storage_bucket       = "your-project.appspot.com"
  identity_platform_messaging_sender_id  = "123456789"
  identity_platform_app_id               = "1:123456789:web:abcdef"
  
  # Auth service URLs
  auth_service_frontend_url = "https://auth.yourdomain.com"
  auth_service_backend_url  = "https://api.auth.yourdomain.com"
  
  arm_canaries = false
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | Ciridae project ID (separate from GCP) | string | - | yes |
| `gcp_project_id` | Google Cloud project ID | string | - | yes |
| `region` | GCP region for resources | string | - | yes |
| `environment` | Deployment environment (dev/staging/prod) | string | - | yes |
| `domain_name` | Custom domain for the application | string | - | yes |
| `identity_platform_api_key` | Firebase/Identity Platform API key | string | - | yes |
| `identity_platform_auth_domain` | Auth domain for Identity Platform | string | - | yes |
| `identity_platform_project_id` | Identity Platform project ID | string | - | yes |
| `identity_platform_storage_bucket` | Storage bucket for Identity Platform | string | - | yes |
| `identity_platform_messaging_sender_id` | FCM sender ID | string | - | yes |
| `identity_platform_app_id` | Firebase app ID | string | - | yes |
| `auth_service_frontend_url` | Frontend URL for auth service | string | - | yes |
| `auth_service_backend_url` | Backend URL for auth service | string | - | yes |
| `is_dev` | Whether this is a development environment | bool | `false` | no |
| `backend_connector_subnetwork_cidr` | `/28` CIDR range reserved for future static backend egress | string | `"10.8.0.0/28"` | no |
| `backend_egress_static_ip_count` | Number of regional static external IP addresses to reserve for backend Cloud NAT egress | number | `1` | no |
| `arm_canaries` | Whether to arm canary alerting after bootstrap | bool | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `artifact_registry_repository_id` | ID of the container registry for backend images |
| `backend_egress_static_ip_addresses` | Static external IP addresses used by backend Cloud NAT egress |
| `gke_cluster_name` | GKE cluster name |
| `gke_connect_gateway_host` | Connect Gateway host for future Kubernetes and Helm providers |
| `frontend_url` | URL of the frontend application |
| `dns_nameservers` | Nameservers to configure at your domain registrar |
| `ds_record_values` | DNSSEC DS records for your domain |
| `ds_record_instructions` | Instructions for adding DS records |
| `crucible_deployment_contract_version` | Deployment contract version for Crucible |
| `terraform_apply_service_account_email` | Service account used by Argo Terraform apply workflow step instances |
| `workflow_submitter_service_account_email` | Service account external callers use to submit Argo workflows |
| `workflow_namespace` | Namespace where Argo deployment workflows run |
| `workflow_template_name` | Argo deployment `WorkflowTemplate` name |
| `workflow_required_parameters` | Parameters required to submit the deployment workflow |

## Created Infrastructure

### Network Layer
* VPC network with custom subnets
* Dedicated subnet reserved for future static backend egress
* Protected reserved static backend egress IPs
* Cloud Router and Cloud NAT gateway scoped only to the reserved backend egress subnet, using the reserved backend egress IPs
* Separate Cloud Router and auto-allocated Cloud NAT gateway for private GKE node egress
* Private service connection for Cloud SQL

### Database Layer
* Cloud SQL PostgreSQL instance
* Private IP only (no public access)
* Automatic backups and maintenance

### Application Layer
* **Backend platform**:
  * Container registry for images
  * Google service account for backend Kubernetes workloads
  * Secret Manager refs exposed to Kubernetes through deployment outputs
  * Reserved regional static API IP assigned to the ingress-nginx controller
  * Injected canary env vars: `SENSITIVE_CANARY_BUCKET_NAME`; when the sensitive canary DB exists (`is_dev = false`), secret env var `CROSS_PROJECT_DB_URL` from `access_canaries.sensitive_db_url`
  * Kubernetes health checks and auto-scaling are defined in `infra/modules/kubernetes/config`
* **Frontend**: Static hosting with:
  * Cloud Storage bucket
  * Global CDN via load balancer
  * SSL certificates
  * Custom domain

### Deployment Workflow Layer
* Service accounts for Argo workflow submission and task-scoped execution
* Workload Identity bindings for Terraform, source inspection, backend image builds, frontend upload, and CDN invalidation
* Sentry auth token Secret Manager secret for frontend sourcemap uploads
* Workflow contract outputs for external Crucible callers
* Integration with container registry, Terraform state, frontend hosting, backend CD tasks, and backend Kubernetes rollout

### DNS Layer
* Cloud DNS managed zone
* DNSSEC enabled
* A records for frontend and backend
* Automatic SSL certificate provisioning

## Post-Deployment Steps

1. **Configure DNS at Registrar**
   ```bash
   # Get nameservers
   terraform output dns_nameservers
   
   # Update your domain registrar with these nameservers
   ```

2. **Enable DNSSEC**
   ```bash
   # Get DS records
   terraform output ds_record_values
   
   # Add these DS records at your domain registrar
   ```

3. **Whitelist Backend Egress Where Needed**
   ```bash
   terraform output -json backend_egress_static_ip_addresses
   ```

   Add these IP addresses to associated services that restrict backend callers by source IP.

4. **Bootstrap Argo and Deploy Initial Application**
   * Ensure `terraform.auto.tfvars` is synced to the remote Terraform state bucket.
   * Run the bootstrap Terraform sequence from local/provisioning to create the cloud substrate, Kubernetes extensions, and deployment workflow config.
   * Authenticate to the cluster through the GKE Connect Gateway.
   * Create a short-lived source auth Secret in the Argo namespace and submit the Terraform-managed `WorkflowTemplate`.
   * Read deployment contract values from the Terraform workflow outputs.

Crucible (`int-provisioning`) uses the uploaded Terraform outputs for later
push deploys, initial full-environment completion, and env-var-triggered
applies/deploys.

## Environment-Specific Features

### Development (`is_dev = true`)
* Public access allowed to backend service
* Database deletion protection disabled
* Lower resource limits for cost optimization

### Production (`is_dev = false`)
* Authentication required for backend
* Database deletion protection enabled
* Higher resource limits and redundancy

## Security Features

* All inter-service communication uses private IPs
* Reserved backend egress IP addresses are protected from accidental destroy for the future static backend egress path
* Private GKE node internet access uses a separate auto-allocated Cloud NAT; backend Kubernetes static egress is deferred to a workload-specific follow-up
* Database accessible only through VPC
* Secrets managed via Secret Manager
* Data access canary alerts for secret reads, bucket reads, and non-dev sensitive DB connections
* Service accounts with minimal permissions
* DNSSEC enabled for DNS
* SSL/TLS for all public endpoints

## Canary Arming

- Default behavior is `arm_canaries = false`.
- `arm_canaries` toggles **only** whether the canary alert policies in `critical_alerting` are enabled. 
- Bootstrap with `arm_canaries = false` so Terraform can create canary resources and upload the seed object without enabling canary Monitoring alerts.
- Flip `arm_canaries = true` in a later apply to enable canary alert policies.

## Cost Optimization

* Shared VPC reduces networking costs
* Lifecycle policies on storage buckets
* Development environments use smaller instances

## Troubleshooting

### DNS Not Resolving
1. Verify nameservers are updated at registrar
2. Check DNS propagation (can take up to 48h)
3. Validate DNSSEC chain if enabled

### Backend Can't Connect to Database
1. Verify Cloud SQL has private IP
2. Ensure the backend Google service account has SQL client role
3. Check the backend pod and Cloud SQL Auth Proxy sidecar logs

### Argo Deployments Failing
1. Check the `Workflow` status and pod logs in the Argo namespace
2. Verify the source auth Secret exists for the run and is deleted by the exit handler afterward
3. Confirm the task Kubernetes service account is bound to the intended Google service account through Workload Identity
4. Check the deployment workflow state ConfigMap before debugging skipped tasks
