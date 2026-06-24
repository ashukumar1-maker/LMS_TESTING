# Storage Module

This Terraform module creates a Google Cloud Storage bucket configured for application data storage with versioning, lifecycle management, and CORS support for frontend access.

## Features

* **Versioning** - Automatic version control for all objects
* **Lifecycle Management** - Automatic cleanup of old versions
* **CORS Support** - Configured for frontend application access
* **Environment-Aware** - Different configurations for dev/prod
* **Security** - Uniform bucket-level access control
* **Cost Optimization** - Automatic deletion of old versions

## Resources Created

1. **Google Storage API** - Enables Cloud Storage service
2. **Storage Bucket** - Application data storage with:
   * Standard storage class
   * Versioning enabled
   * Lifecycle rules
   * CORS configuration
   * Environment labels
   * Deletion protection

## Usage

```hcl
module "storage" {
  source = "./modules/gcp/storage"

  gcp_project_id = "your-gcp-project-id"
  project_id     = "your-ciridae-project-id"
  region         = "us-central1"
  environment    = "dev"
  is_dev         = true
  frontend_url   = "https://example.com"
  
  # Optional: Custom bucket suffix
  bucket_name_suffix = "app-data"  # Default
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `gcp_project_id` | The Google Cloud project ID | string | - | yes |
| `project_id` | The Ciridae project ID | string | - | yes |
| `region` | GCS bucket region | string | - | yes |
| `environment` | Deployment environment | string | - | yes |
| `is_dev` | Development environment flag | bool | - | yes |
| `frontend_url` | Frontend URL for CORS | string | - | yes |
| `bucket_name_suffix` | Bucket name suffix | string | `"app-data"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the created storage bucket |

## Bucket Configuration

### Naming Convention
Buckets are named using the pattern: `{project_id}-{environment}-{bucket_name_suffix}`

Examples:
* `myproject-dev-app-data`
* `myproject-staging-app-data`
* `myproject-prod-app-data`

### Versioning
* All objects are versioned automatically
* Previous versions retained for 7 days
* Protects against accidental overwrites/deletions

### Lifecycle Rules
```hcl
{
  action: "Delete"
  condition: {
    age: 7
    with_state: "ARCHIVED"
  }
}
```

### CORS Configuration

Development environments include localhost:
```javascript
origins: ["http://localhost:3000", "https://frontend-url"]
methods: ["PUT"]
headers: ["*"]
```

Production environments use only the frontend URL:
```javascript
origins: ["https://frontend-url"]
methods: ["PUT"]
headers: ["*"]
```

## Security Features

1. **Uniform Bucket-Level Access** - Consistent IAM policies
2. **No Public Access** - Private by default
3. **Deletion Protection** - Lifecycle rule prevents accidental deletion
4. **Versioning** - Protects against data loss

## Usage Patterns

### Direct Upload from Frontend

The CORS configuration allows direct uploads from your frontend:

```javascript
// Frontend upload example
const uploadFile = async (file) => {
  const response = await fetch(`https://storage.googleapis.com/${bucketName}/${file.name}`, {
    method: 'PUT',
    body: file,
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': file.type
    }
  });
};
```

### Resumable Uploads

CORS headers support resumable uploads for large files:

```javascript
// Using Google Cloud Storage resumable upload
const upload = new Upload({
  bucket: bucketName,
  file: largeFile,
  metadata: {
    resumable: true
  }
});
```

### Backend Access

Backend services can access the bucket using service account credentials:

```python
# Python example
from google.cloud import storage

client = storage.Client()
bucket = client.bucket(bucket_name)
blob = bucket.blob('path/to/file')
blob.upload_from_filename('local-file.txt')
```

## Cost Optimization

1. **Lifecycle Rules** - Old versions deleted after 7 days
2. **Standard Storage** - Most cost-effective for frequently accessed data
3. **Regional Bucket** - Lower cost than multi-regional

## Monitoring

Monitor bucket usage with Cloud Monitoring:
* Storage size and growth
* Request rates and errors
* Bandwidth usage
* Object count and versions

## Best Practices

1. **Use Folders** - Organize objects with folder prefixes
2. **Set Content Types** - Specify MIME types for proper handling
3. **Enable Compression** - Compress text files before upload
4. **Use Signed URLs** - For temporary access to private objects
5. **Monitor Costs** - Set up billing alerts for storage

## Integration Examples

### With Backend Service

The backend module can mount this bucket:
```hcl
storage_bucket_name = module.storage.bucket_name
```

### With Frontend Upload

Configure your frontend with the bucket name:
```javascript
const STORAGE_BUCKET = process.env.VITE_STORAGE_BUCKET_NAME;
```

### With Deployment Workflow

Grant the frontend deployment workflow task access for uploads:
```hcl
resource "google_storage_bucket_iam_member" "frontend_deployer_write" {
  bucket = module.storage.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.deployment.workflow_step_service_account_emails.frontend_deployer}"
}
```

## Troubleshooting

### CORS Errors
1. Verify frontend URL matches CORS origin exactly
2. Check authentication headers are included
3. Ensure HTTP method is allowed (PUT)

### Access Denied
1. Verify service account has storage permissions
2. Check bucket IAM policies
3. Ensure uniform bucket-level access is enabled

### Version Cleanup Not Working
1. Check lifecycle rule is active
2. Verify objects are marked as non-current
3. Wait for daily lifecycle execution

## Limitations

* Bucket names must be globally unique
* CORS origins must be exact matches (no wildcards)
* Lifecycle rules run once daily
* Cannot change location after creation
