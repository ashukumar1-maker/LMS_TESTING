# Azure Build and Push Backend Image CD Step

Defines the Azure-specific Argo `Template` for the `backend-build` workflow
task. This step builds and pushes the backend container image through Azure
Container Registry Tasks instead of building inside the workflow pod.

## Responsibilities

- Accepts the desired backend image URI from the shared workflow.
- Validates that the image reference belongs to the configured ACR login server.
- Parses the repository name and tag from the desired image URI.
- Authenticates to Azure with Workload Identity through `az login --service-principal`.
- Submits an `az acr run` quick task that builds `backend/Dockerfile` and pushes
  both the commit-specific tag and `:latest`.

## Workflow Integration

- Argo template name: `backend-build`
- DAG task name: `backend-build`
- Runs after Terraform convergence and `inspect-source` succeed.
- Runs only in `BACKEND_ONLY` or `FULL` deployment modes when
  `backend-build-needed` is `true`.
- Receives `desired-image` from `inspect-source.outputs.parameters.desired-image`.
- Successful completion is required before backend CD tasks and `backend-rollout`.

The build context is `/workspace/repo/backend` on the shared workflow PVC. The
ACR task file enables BuildKit inline cache and reuses the existing `:latest`
image as a cache source.

## Key Inputs

- `step_service_account_name`: Kubernetes service account used by the Argo step.
  Wired from the `backend_builder` workflow identity in
  `infra/modules/azure/ci_cd`.
- `azure_subscription_id`: Subscription passed to `az acr run --subscription`.
- `container_registry_login_server`: ACR login server used to validate and parse
  the desired image URI.
- `azure_cli_image`: Container image for the step. Defaults to
  `mcr.microsoft.com/azure-cli:2.77.0`.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

This is the steady-state backend image delivery path for Azure environments. The
one-time Terraform bootstrap image push in `infra/modules/azure/backend` seeds
ACR with `backend:init` before the first successful workflow build.

The step uses Azure AD auth from the workflow pod identity. ACR admin
credentials remain disabled. The `backend_builder` identity needs permission to
queue ACR Tasks quick builds and push images, which `infra/modules/azure/ci_cd`
grants at the registry scope.

`az account set` is not required when `--subscription` is passed directly to
`az acr run`.
