# Setup Guide

## Required software

- Terraform (`brew install terraform`)
- Google Cloud SDK (`brew install google-cloud-sdk`)

## Authentication

Authenticate with Google Cloud SDK

```bash
gcloud auth application-default login
```

## Argo Workflow Deployment Prerequisites

Cloud Build is not part of the steady-state deployment path. Provisioning
creates Argo Workflows in the GKE cluster, deployment task service accounts, and
the IAM needed by each workflow step.

First-time bootstrap is intentionally small: run Terraform from local tooling or
provisioning to create the cloud substrate, Kubernetes extensions, and
deployment workflow config. After that, Crucible
(`int-provisioning`) authenticates through GKE Connect Gateway, creates a
short-lived source auth Secret in the Argo namespace, and submits the
Terraform-managed deployment `WorkflowTemplate`.

`terraform.auto.tfvars` must exist in the Terraform state bucket before Argo
runs because the workflow pulls state and tfvars from that bucket instead of
accepting tfvars as workflow parameters.

The workflow submitter passes only the temporary source auth Secret name, the
commit SHA to deploy, and a deployment mode (`INFRA_ONLY`, `BACKEND_ONLY`,
`FRONTEND_ONLY`, or `FULL`). Environment-specific metadata such as image
repository, Kubernetes object names, bucket names, CDN names, and frontend build
variables is wired into the `WorkflowTemplate` by Terraform.

## Environment Variables

Create `terraform.auto.tfvars` in the environment you are deploying to with the following variables:

```tfvars
project_name               = "YOUR_PROJECT_NAME"
project_id                 = "YOUR_PROJECT_ID"
gcp_project_id             = "YOUR_GCP_PROJECT_ID"
cloud                      = "gcp"
environment                = "YOUR_ENVIRONMENT"
domain_name                = "YOUR_DOMAIN_NAME"
source_repository_url      = "https://YOUR_GIT_HOST/YOUR_ORG/YOUR_REPO.git"
```

Note: These variables are optional:
- `cloud` (defaults to `"gcp"`; AzureTest uses `"azure"`)
- `region` (defaults to `"us-central1"`)
- `is_dev` (defaults to `false`)
- `critical_alert_emails` (defaults to `[]`; set in `terraform.auto.tfvars` to receive critical Cloud Monitoring alerts)
- `critical_alert_phone_numbers` (defaults to `[]`)

**Important**: The GCP project must exist before running Terraform.

For AzureTest, use `infra/environments/azuretest` and set
`azure_subscription_id` instead of `gcp_project_id`. Do not add a generic cloud
account variable.

## Project Prerequisites

Before running Terraform, ensure the Cloud Resource Manager API is enabled on your project:

```bash
gcloud services enable cloudresourcemanager.googleapis.com --project={PROJECT_ID}-{environment}
```

This API must be enabled manually. All other required APIs will be enabled automatically by Terraform.
