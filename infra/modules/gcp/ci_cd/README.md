# Deployment Orchestration Module

This module creates the GCP identities and IAM used by the in-cluster Argo
deployment workflow. It does not create Cloud Build resources, source host
connections, or build triggers.

## Resources Created

- Workflow submitter Google service account for external callers.
- Terraform apply Google service account for Argo Terraform step instances.
- Task-scoped Google service accounts for source inspection, backend image
  builds, frontend uploads, and CDN invalidation.
- Sentry auth token Secret Manager secret for frontend sourcemap uploads.
- Workload Identity bindings from task Kubernetes service accounts in the Argo
  namespace to the matching Google service accounts.
- IAM for Artifact Registry, Terraform state, frontend bucket writes, CDN
  invalidation, and Sentry token access.

## Workflow Contract

An external caller, currently Crucible (`int-provisioning`), authenticates to the
cluster through Connect Gateway, creates a short-lived source auth Secret in the
Argo namespace, and submits the Terraform-managed deployment `WorkflowTemplate`.

The first environment bootstrap is intentionally smaller than the steady-state
workflow: provisioning or an operator target-applies cloud infrastructure, Argo,
and workflow templates first. After Argo exists, the workflow clones the repo,
pulls Terraform state and `terraform.auto.tfvars` from the state bucket, runs
conditional Terraform/code/frontend steps, pushes state, and records successful
hashes in the workflow state ConfigMap.

## Outputs

| Name | Description |
|------|-------------|
| `workflow_submitter_service_account_email` | External caller identity for submitting Argo workflows |
| `terraform_apply_service_account_email` | Google service account used by Argo Terraform step instances |
| `workflow_namespace` | Namespace where Argo deployment workflows run |
| `workflow_template_name` | Name of the deployment `WorkflowTemplate` |
| `workflow_kubernetes_service_accounts` | Kubernetes service account names used by workflow step instance pods |
| `workflow_step_service_account_emails` | Google service account emails used by workflow step service account pods |
| `workflow_required_parameters` | Required parameters for workflow submission |
| `crucible_deployment_contract_version` | Deployment contract version for Crucible |
| `sentry_auth_token_secret_id` | Secret Manager ID for the Sentry auth token secret |
| `sentry_auth_token_secret_name` | Secret Manager secret name for the Sentry auth token |

## Notes

- Deployment-time backend tasks run in the backend branch of the Argo workflow.
- `terraform.auto.tfvars` is not passed as a workflow parameter and is not cloned
  from Git. It must exist in the Terraform state bucket before the workflow runs.
