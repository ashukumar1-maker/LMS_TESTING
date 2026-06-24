# Frontend Module

This Terraform module provisions a production-ready static website hosting infrastructure on Google Cloud Platform with global content delivery, HTTPS support, and managed SSL certificates.

## Features

* **Global CDN** - Cloud CDN for fast content delivery worldwide
* **HTTPS Support** - Automatic SSL certificate provisioning and management
* **Static Website Hosting** - Cloud Storage bucket optimized for web content
* **Load Balancing** - Global HTTP(S) load balancer with static IP
* **High Availability** - Multi-region content serving
* **Security** - Uniform bucket-level access with public read permissions

## Resources Created

1. **Google Compute API** - Enables required GCP services
2. **Storage Bucket** - Hosts static frontend files with:
   * Website configuration
   * Uniform bucket-level access
   * Lifecycle protection
   * Public read access
3. **Static IP Address** - Reserved global IP for consistent DNS
4. **Backend Bucket** - CDN-enabled backend for the storage bucket
5. **URL Map** - Routes requests to the backend bucket
6. **SSL Certificate** - Managed certificate for HTTPS
7. **Load Balancers**:
   * HTTP Proxy and Forwarding Rule (port 80)
   * HTTPS Proxy and Forwarding Rule (port 443)

## Usage

```hcl
module "frontend" {
  source = "./modules/gcp/frontend"

  gcp_project_id  = "your-gcp-project-id"
  project_id      = "your-ciridae-project-id"
  region          = "us-central1"
  environment     = "prod"
  domain_name     = "example.com"
  
  # Optional: Custom index page
  main_page_suffix = "index.html"  # Default
  
  # Optional: Force destroy bucket on deletion
  force_destroy = false  # Default: true
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `gcp_project_id` | The GCP project ID | string | - | yes |
| `project_id` | The Ciridae project ID | string | - | yes |
| `region` | Storage bucket region | string | - | yes |
| `environment` | Deployment environment | string | - | yes |
| `domain_name` | Domain for SSL certificate | string | - | yes |
| `main_page_suffix` | Index document name | string | `"index.html"` | no |
| `force_destroy` | Allow bucket destruction with content | bool | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the storage bucket |
| `bucket_url` | GCS URL of the bucket (gs://) |
| `cdn_ip_address` | IP address of the CDN endpoint |
| `frontend_url` | HTTP URL of the frontend |
| `https_frontend_url` | HTTPS URL of the frontend |
| `load_balancer_ip_address` | Static IP for DNS configuration |
| `url_map_name` | Name of the URL map (for cache invalidation) |

## Architecture

```
Internet → Global Load Balancer (HTTP/HTTPS)
              ↓
         Backend Bucket (CDN)
              ↓
      Storage Bucket (Static Files)
```

## Bucket Naming

The storage bucket is named using the pattern: `{project_id}-{environment}-frontend`

For example:
* `myproject-dev-frontend`
* `myproject-staging-frontend`
* `myproject-prod-frontend`

## Post-Deployment Steps

### 1. Configure DNS

Create an A record pointing to the load balancer IP:
```bash
# Get the IP address
terraform output -module=frontend load_balancer_ip_address

# Add A record at your DNS provider
example.com → <IP_ADDRESS>
```

### 2. Deploy Frontend Files

Upload your built frontend files to the bucket:
```bash
# Get bucket name
BUCKET=$(terraform output -module=frontend bucket_name)

# Upload files (example for React/Vue/Angular build)
gsutil -m rsync -r -d ./dist gs://$BUCKET/
```

### 3. Verify SSL Certificate

SSL certificates can take up to 60 minutes to provision:
```bash
# Check certificate status
gcloud compute ssl-certificates describe frontend-ssl-cert-{environment}
```

## File Structure

Your frontend build should follow this structure:
```
dist/
├── index.html          # Main page (main_page_suffix)
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
└── favicon.ico
```

## URL Structure

The module creates these endpoints:
* `http://<IP_ADDRESS>` - HTTP endpoint (redirects recommended)
* `https://<IP_ADDRESS>` - HTTPS endpoint
* `https://example.com` - Domain endpoint (after DNS configuration)

## CDN Cache Management

### Invalidate Specific Paths
```bash
gcloud compute url-maps invalidate-cdn-cache {url_map_name} \
  --path "/*" \
  --project {gcp_project_id}
```

### Cache Headers
Configure cache headers in your frontend build:
* Static assets (JS, CSS): `Cache-Control: public, max-age=31536000`
* HTML files: `Cache-Control: no-cache`

## Security Features

1. **Uniform Bucket Access** - Consistent permissions across all objects
2. **Public Read Only** - No public write access
3. **HTTPS by Default** - SSL certificate for encrypted connections
4. **No Directory Listing** - Only specified files are accessible

## Cost Optimization

* **CDN Caching** - Reduces egress costs
* **Regional Bucket** - Lower storage costs than multi-region
* **Lifecycle Policies** - Can be added for old content

## Monitoring

Monitor your frontend with Cloud Monitoring:
* CDN hit ratio
* Request latency
* Error rates
* Bandwidth usage

## Troubleshooting

### SSL Certificate Not Working
1. Verify domain ownership is complete
2. Check certificate status: `gcloud compute ssl-certificates list`
3. Ensure DNS points to the correct IP
4. Wait up to 60 minutes for provisioning

### 404 Errors
1. Verify `index.html` exists in bucket root
2. Check bucket permissions are public
3. For SPAs, all routes should return `index.html`

### Slow Performance
1. Check CDN hit ratio in Cloud Console
2. Verify correct cache headers on assets
3. Enable compression in your build process

## Single Page Application (SPA) Support

For SPAs with client-side routing:
1. All routes return `index.html` (configured automatically)
2. Handle 404s in your frontend application
3. Use proper cache headers for dynamic content

## Limitations

* SSL certificates require valid domain ownership
* Bucket names must be globally unique
* No server-side rendering support
* No custom error pages (uses main_page_suffix for 404s)
* HTTPS redirect must be handled at application level