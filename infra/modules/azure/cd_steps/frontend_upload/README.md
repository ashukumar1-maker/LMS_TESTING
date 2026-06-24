# Azure Frontend Upload CD Step

Defines the Azure-specific Argo `Template` for the `frontend-upload` workflow
task. This step syncs the built frontend assets into the Azure Storage static
website container.

## Responsibilities

- Authenticates to Azure with Workload Identity through `az login --service-principal`.
- Installs AzCopy into the Azure CLI user bin directory so `az storage blob sync`
  does not rely on Azure CLI's runtime AzCopy download path.
- Runs `az storage blob sync` against the configured storage account.
- Uploads `/workspace/repo/frontend/dist` into the `$web` container.
- Deletes destination blobs that no longer exist in the local build output.

## Workflow Integration

- Argo template name: `frontend-upload`
- DAG task name: `frontend-upload`
- Runs after `frontend-build` succeeds.
- Runs only in `FRONTEND_ONLY` or `FULL` deployment modes when
  `frontend-deploy-needed` is `true`.
- Successful completion is required before `cdn-invalidate`.

The upload source is `/workspace/repo/frontend/dist` on the shared workflow PVC.
That directory is produced by the shared `frontend-build` step in
`infra/modules/kubernetes/cd_workflow`.

## Key Inputs

- `step_service_account_name`: Kubernetes service account used by the Argo step.
  Wired from the `frontend_deployer` workflow identity in
  `infra/modules/azure/ci_cd`.
- `azure_subscription_id`: Subscription passed to
  `az storage blob sync --subscription`.
- `frontend_storage_account_name`: Storage account that hosts the static website.
  Wired from `frontend_bucket_name` in the shared CD workflow module.
- `azure_cli_image`: Container image for the step. Defaults to
  `mcr.microsoft.com/azure-cli:2.77.0`.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

The step uses `--auth-mode login`, so blob access is authorized through Azure AD
rather than storage account keys or SAS tokens.

The `$web` container name is required for Azure static website hosting. The
`frontend_deployer` identity is scoped to that container by
`infra/modules/azure/ci_cd`.

Subscription scoping is passed per command with `--subscription` instead of
mutating the shell default through `az account set`.
