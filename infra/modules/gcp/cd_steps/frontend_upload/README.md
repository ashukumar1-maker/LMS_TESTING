# GCP Frontend Upload CD Step

Defines the GCP-specific Argo `Template` for the `frontend-upload` workflow
task. This step uploads the built frontend assets into the GCS frontend bucket.

## Responsibilities

- Runs `gsutil -m rsync -r` against the configured frontend bucket.
- Uploads `/workspace/repo/frontend/dist` from the shared workflow PVC.
- Uses parallel `gsutil` transfers for faster uploads.

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
  `infra/modules/gcp/ci_cd`.
- `frontend_bucket_name`: GCS bucket that stores frontend assets. Wired from the
  shared CD workflow module.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

The step uses the `gcr.io/google.com/cloudsdktool/cloud-sdk:slim` image and
relies on GCP Workload Identity for bucket access. The `frontend_deployer`
service account receives object admin access to the frontend bucket in
`infra/modules/gcp/ci_cd`.

`gsutil rsync` updates changed objects and removes destination objects that no
longer exist in the source directory, similar in intent to the Azure blob sync
step's `--delete-destination true` behavior.
