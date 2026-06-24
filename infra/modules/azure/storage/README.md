# Azure Storage Module

Creates Azure Storage resources used by backend mounted application data.

## Responsibilities

- Creates the private `backend` blob container.

## Key Inputs

- `storage_account_id`: Shared Azure Storage account created by the deployment
  module.
- `storage_account_name`: Storage account name passed through to backend runtime
  outputs and environment variables.
- `project_id`, `environment`: Deployment identity used for module consistency.

## Outputs

- `storage_account_id`, `storage_account_name`: Used by backend runtime wiring.
- `backend_container_name`: Backend mounted-storage container name.

## Notes

The backend container is private. Runtime access uses AKS Workload Identity plus
Azure Blob CSI wiring in the Kubernetes workload module.

Frontend static website hosting belongs to `infra/modules/azure/frontend`.
Terraform state synchronization belongs to `infra/modules/azure/bucket_for_tf_state`.
