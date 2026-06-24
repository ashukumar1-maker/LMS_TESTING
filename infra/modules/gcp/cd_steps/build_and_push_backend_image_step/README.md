# GCP Build and Push Backend Image CD Step

Defines the GCP-specific Argo `Template` for the `backend-build` workflow task.
This step builds and pushes the backend container image with Kaniko directly
inside the workflow pod.

## Responsibilities

- Accepts the desired backend image URI from the shared workflow.
- Builds the backend image from `/workspace/repo/backend`.
- Pushes the built image to the configured Artifact Registry repository URI.
- Enables Kaniko layer caching for faster repeat builds.

## Workflow Integration

- Argo template name: `backend-build`
- DAG task name: `backend-build`
- Runs after Terraform convergence and `inspect-source` succeed.
- Runs only in `BACKEND_ONLY` or `FULL` deployment modes when
  `backend-build-needed` is `true`.
- Receives `desired-image` from `inspect-source.outputs.parameters.desired-image`.
- Successful completion is required before backend CD tasks and `backend-rollout`.

The build context is `/workspace/repo/backend` on the shared workflow PVC.

## Key Inputs

- `step_service_account_name`: Kubernetes service account used by the Argo step.
  Wired from the `backend_builder` workflow identity in
  `infra/modules/gcp/ci_cd`.
- `kaniko_image`: Container image for the step. Defaults to
  `gcr.io/kaniko-project/executor:v1.23.2`.

## Outputs

- `template`: Argo `Template` object merged into the shared
  `WorkflowTemplate.spec.templates[]` list.

## Notes

Kaniko authenticates to Artifact Registry through the workflow pod's GCP
Workload Identity credentials. The `backend_builder` service account receives
the Artifact Registry write permissions needed for image push in
`infra/modules/gcp/ci_cd`.

Unlike the Azure path, this step does not call a remote build service. The image
build runs in-cluster and only the registry push leaves the workflow pod.
