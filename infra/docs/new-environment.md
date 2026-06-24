# How to create a new environment

To create a new environment (e.g., staging or prod), follow these steps:

1. **Copy an existing environment directory:**
   ```bash
   cd infra/environments
   cp -r dev staging  # Replace 'staging' with your environment name
   ```

2. **IMPORTANT: Remove all Terraform state files from the copied directory:**
   
   **WARNING**: Only delete these files from the NEW copied directory, never from the original!

3. **Create the GCP project** for your new environment:
   - The project ID should follow the pattern: `{project_id}-{environment}` (e.g., `myproject-staging`)
   - Ensure the billing account is linked to the project
   - **Enable the Cloud Resource Manager API manually** (this must be done before Terraform can run):
     ```bash
     gcloud services enable cloudresourcemanager.googleapis.com --project={PROJECT_ID}-{environment}
     ```
   - All other APIs will be enabled automatically by Terraform

4. **Update the `terraform.auto.tfvars` file** in the new environment directory with appropriate values:
   - Update `project_id` to match your new environment
   - Keep `cloud = "gcp"` unless another provider implementation has been added
   - Update `environment` to your new environment name
   - Update `domain_name` if using a different subdomain
   - No Cloud Build configuration is required. Crucible (`int-provisioning`) submits the Terraform-managed Argo deployment `WorkflowTemplate` after bootstrap.
   - Ensure `terraform.auto.tfvars` is synced to the Terraform state bucket before submitting the first Argo workflow.
   - Bootstrap creates the cloud substrate, Kubernetes extensions, and deployment workflow config; the Argo workflow runs the full conditional infrastructure and code deployment after it exists.
   - Adjust other variables as needed for your environment

5. **Initialize and deploy the new environment:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
