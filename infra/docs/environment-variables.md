# Environment Variables Guide

This guide explains how to add and manage environment variables across your infrastructure.

## Types of Environment Variables

### 1. Backend Environment Variables (`backend_env_vars`)

Non-sensitive configuration values uploaded to the backend Kubernetes
`backend-env` ConfigMap and consumed by the backend Deployment.

```hcl
# In terraform.auto.tfvars
backend_env_vars = {
  LOG_LEVEL = "info"
  MAX_WORKERS = "4"
  FEATURE_FLAG_NEW_UI = "true"
}
```

### 2. Backend Secret Environment Variables (`backend_secret_env_vars`)

Sensitive values stored in Google Secret Manager and exposed to Kubernetes
through External Secrets.

```hcl
# In terraform.auto.tfvars
backend_secret_env_vars = {
  API_KEY = "your-secret-api-key"  
  THIRD_PARTY_SECRET = "secret-value"
  OAUTH_CLIENT_SECRET = "oauth-secret"
}
```

### 3. Frontend Environment Variables (`frontend_env_vars`)

Build-time variables injected during the frontend build process. Must start with `VITE_`.

```hcl
# In terraform.auto.tfvars
frontend_env_vars = {
  VITE_FEATURE_FLAG = "true"
  VITE_PUBLIC_API_ENDPOINT = "https://external-api.com"
  VITE_APP_VERSION = "1.2.3"
}
```

## How to Add New Environment Variables

**⚠️ IMPORTANT: You must repeat these steps for EVERY environment (dev, staging, prod) where you want the variables!**

**⚠️ WARNING: Running `terraform apply` will apply ALL changes in the terraform configuration, including any unmerged changes. To avoid this, checkout the appropriate branch for each environment before making changes.**

### Safe Approach - Work on Environment-Specific Branches

The appropriate branches for each environment are:
- **dev** environment → `dev` branch
- **staging** environment → `staging` branch  
- **prod** environment → `prod` branch

1. **For each environment, checkout the appropriate branch**:
   ```bash
   # For dev environment
   git checkout dev
   
   # For staging environment  
   git checkout staging
   
   # For prod environment
   git checkout prod
   ```

2. **Navigate to the environment directory**:
   ```bash
   cd infra/environments/dev  # or staging/prod
   ```

3. **Pull the latest state from cloud storage**:
   ```bash
   uv run ../../scripts/pullstate.py
   ```

4. **Edit `terraform.auto.tfvars`** to add your variables to the appropriate section

5. **Apply the changes**:
   ```bash
   terraform apply
   ```

6. **Push state back to cloud storage**:
   ```bash
   uv run ../../scripts/pushstate.py
   ```

7. **Repeat steps 1-6 for each environment** where you need these variables

## How Variables Are Used

### Backend Variables

Environment variables are automatically loaded in `backend/src/config.py`:

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Existing variables
    DATABASE_URL: str
    GOOGLE_CLOUD_PROJECT: str
    
    # Your new variables
    LOG_LEVEL: str = "info"  # From backend_env_vars
    API_KEY: str  # From backend_secret_env_vars
    
settings = Settings()

# Use in your code
print(f"Log level: {settings.LOG_LEVEL}")
print(f"API key: {settings.API_KEY}")
```

### Frontend Variables

Access via `import.meta.env`:

```typescript
// In any frontend component or module
const featureFlag = import.meta.env.VITE_FEATURE_FLAG;
const apiEndpoint = import.meta.env.VITE_PUBLIC_API_ENDPOINT;
const appVersion = import.meta.env.VITE_APP_VERSION;
```

## Important Notes

- **Backend variables**: Non-sensitive values are uploaded to the `backend-env`
  ConfigMap. Backend pods see changes after the Kubernetes Deployment rolls out
  or the pods are restarted.

- **Secrets**: Stored in Google Secret Manager with names like `dev-backend-api-key`
  and synchronized into the backend namespace by External Secrets. The
  `backend-secrets` ExternalSecret refreshes every hour by default, so a new
  Secret Manager version can take up to about one hour to appear in Kubernetes.
  To expedite propagation, force a refresh and then restart the backend pods so
  env-var based secrets are reread:
  ```bash
  kubectl -n backend annotate externalsecret backend-secrets force-sync="$(date +%s)" --overwrite
  kubectl -n backend get externalsecret backend-secrets -o yaml | grep refreshTime
  kubectl -n backend rollout restart deployment/backend
  kubectl -n backend rollout status deployment/backend --timeout=600s
  ```

- **DATABASE_URL**: Special secret that auto-updates when database credentials change

- **Security**: Never commit sensitive values to git. Always use `backend_secret_env_vars` for sensitive data.

## Viewing Current Variables

To see what environment variables are currently set:

1. **Backend ConfigMap in Kubernetes**:
   ```bash
   kubectl -n backend describe configmap backend-env
   ```

2. **Backend secret refs in Kubernetes**:
   ```bash
   kubectl -n backend describe configmap backend-secret-refs
   kubectl -n backend describe externalsecret backend-secrets
   kubectl -n backend get externalsecret backend-secrets -o yaml | grep refreshTime
   ```

3. **Secrets in Secret Manager**:
   - Go to Secret Manager in GCP Console
   - Look for secrets named like `{env}-backend-{variable-name}`

4. **In Terraform state**:
   ```bash
   cd infra/environments/dev
   terraform show | grep -A 10 "env_vars\|secret_env_vars"
   ```
