# Azure Terraform State Container

Creates the Azure Blob container used by the repository's Terraform state and
tfvars synchronization scripts.

## Responsibilities

- Creates the private `terraform-state` container in the shared Azure Storage
  account created by the deployment module.

## Notes

The container name is part of the Azure state sync contract. Do not rename it
unless the state scripts are updated at the same time.
