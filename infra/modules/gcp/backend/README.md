# Backend GCP Platform Module

This module provisions GCP resources used by the backend Kubernetes runtime:

- Artifact Registry repository for backend images
- One-time Cloud Build bootstrap that pushes the default `:init` backend image
- Backend Google service account and IAM grants
- Secret Manager secrets and refs for runtime configuration
- Regional static IP assigned to the ingress-nginx controller service

The backend HTTP runtime is no longer Cloud Run. Kubernetes runtime resources
live in `infra/modules/kubernetes/config`.

## Deployment Flow

Terraform creates the platform resources and the Kubernetes module creates the
Deployment, Service, Ingress, External Secrets resources, and HPA. The Argo
deployment workflow builds backend images and rolls out the Kubernetes
Deployment when the backend source changes.

The Terraform-managed initial image push seeds Artifact Registry with the
default `:init` image used by fresh Kubernetes Deployments before the first
successful Argo backend deployment. This is a bootstrap compatibility path, not
the steady-state deployment runner.

## Runtime Contract Outputs

This module exposes:

- `service_name`: backend image/resource name
- `service_account_email`: Google service account for backend workloads
- `artifact_repository_name`: Artifact Registry repository name
- `ingress_nginx_ip_name` and `ingress_nginx_ip_address`: reserved static API IP for ingress-nginx
- `backend_runtime_env_vars`: non-secret env vars for ConfigMaps
- `backend_secret_refs`: Secret Manager refs consumed by External Secrets

## IAM

The backend Google service account gets Artifact Registry reader, Cloud SQL
client, Storage Object Admin, and Workload Identity access for the backend
Kubernetes service account.

External Secrets gets Secret Manager accessor grants for backend secrets through
the Secret Manager module.
