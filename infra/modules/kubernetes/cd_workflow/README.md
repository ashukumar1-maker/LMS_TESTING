# CD Workflow

Defines the Argo `WorkflowTemplate` used for infrastructure and application
deployment. This module owns the cloud-neutral Kubernetes/Argo composition;
provider-specific steps are injected from provider modules such as
`infra/modules/gcp/cd_steps`.

The workflow is created with Terraform's generic `kubernetes_manifest`
resource. The Argo CRDs define the actual Kubernetes schema, so Terraform can
validate HCL syntax and object construction, but it cannot give these locals a
compile-time Argo-specific type.

## Terminology

This module uses `step`, `step_template`, and `step_instance` to make the Argo
workflow structure easier to read in Terraform. Argo's CRD still uses the field
name `tasks` for DAG entries, so strings like `dag.tasks` and
`{{tasks.inspect-source.outputs...}}` are left as Argo requires them.

A step is a logical unit of deployment work, such as cloning source, applying a
Terraform target, building the backend image, uploading frontend assets, or
recording final deployment state. In this module, a runnable step is usually
represented by both a step template and a step instance.

A step template is the reusable Argo `Template` definition in
`WorkflowTemplate.spec.templates[]`. It describes how a step runs. A step
template is usually comprised of a `name`, a workload body such as `container`,
`resource`, or `dag`, the Kubernetes `serviceAccountName`, optional `inputs`,
`outputs`, `volumes`, `metadata`, and any scheduling settings added during
workflow assembly. Terraform locals and files for these objects use the
`*_step_template` or `*_step_templates` suffix.

A step instance is an entry in the root deployment DAG's `tasks[]` list. It says
when and how to invoke a step template in a specific workflow run. A step
instance is usually comprised of a unique `name`, a `template` reference,
dependency logic in `depends`, optional execution guards in `when`, and optional
`arguments` passed to the referenced step template. Terraform locals and files
for these objects use the `*_step_instance` or `*_step_instances` suffix.

Backend CD tasks are a separate product-level concept: user-defined Python jobs
configured with `backend_cd_tasks`. The workflow renders each backend CD task as
both a `backend-cd-task-*` step template and a matching backend CD task step
instance.

The HCL locals in this module intentionally mirror Argo objects:

- `kubernetes_manifest.cd_workflow_template` implements an Argo `WorkflowTemplate`.
- `*_step_template` locals implement entries in `WorkflowTemplate.spec.templates[]`,
  which are Argo `Template` objects.
- `workflow_dag_step_instances` implements entries in a `DAGTemplate.tasks[]` list.

Schema references:

- Argo `WorkflowTemplate`: https://argo-workflows.readthedocs.io/en/latest/fields/#workflowtemplate
- Argo `WorkflowSpec`: https://argo-workflows.readthedocs.io/en/latest/fields/#workflowspec
- Argo `Template`: https://argo-workflows.readthedocs.io/en/latest/fields/#template
- Argo `DAGTask`: https://argo-workflows.readthedocs.io/en/latest/fields/#dagtask

Shared steps own source cloning, change inspection, Terraform convergence,
backend deployment-time tasks, backend rollout, frontend builds, final CD state
recording, and temporary source auth Secret deletion. Provider-specific steps
own cloud APIs such as backend image build/push, object storage upload, and CDN
invalidation. For example, GCP-specific steps live under
`infra/modules/gcp/cd_steps`.

The shared workflow accepts provider-specific values through Terraform module
configuration where possible. For example, backend build and rollout use the
module-configured backend image repository plus `commit-sha`, instead of asking
the workflow caller for GCP project and Artifact Registry fields.

Terraform convergence emits several Argo templates instead of one large step.
Those steps share the workflow PVC at `/workspace`, so the cloned repo,
`.terraform` directory, local state files, `/workspace/bin/terraform`, and the
GKE auth plugin copied into `/workspace/bin` are visible across prepare, target
convergence, output, and push-state step instances. Target convergence applies
`module.deployment`, then `module.kubernetes_crds`, then the full root module.
The push-state step instance is scheduled with enhanced `depends` logic so it
runs after Terraform step instances reach terminal states, including failures.

Workspace-bound templates use a ReadWriteOnce PVC. The workflow starts a
daemon `workspace-anchor` pod first and applies required pod affinity to the
templates that mount the workspace, so they schedule onto the same node as the
live anchor pod. Do not replace the anchor with affinity to `clone-source`:
completed pods are terminal and are not a reliable scheduler affinity target.

The `terraform-output` task runs even when `deployment-mode` skips Terraform
apply. This gives backend/frontend-only runs a fresh `/workspace/terraform-outputs.json`
from the pulled state. Frontend build and source inspection read
`frontend_env_vars` from that JSON instead of baking those values into this
Terraform-managed `WorkflowTemplate`; changing additional frontend env vars only
requires the state output to be updated, not a second apply to rewrite the
workflow template.
Use `FULL` when a commit changes Terraform-managed frontend env vars and should
also deploy frontend assets in the same workflow run. Use `INFRA_ONLY` first
when you only want to refresh state, then a later `FRONTEND_ONLY` run can read
those refreshed values from state.

## Workflow State ConfigMap

Terraform creates an empty ConfigMap (`kubernetes_config_map_v1.workflow_state` in
`main.tf`) in the Argo namespace. The default name is
`deployment-workflow-state` (`workflow_state_config_map_name`). Terraform uses
`lifecycle { ignore_changes = [data] }`, so later applies do not reset runtime
updates.

Successful workflow runs patch `data` with `kubectl patch --type merge`. Each key
is a plain string. Missing keys are treated as empty when the workflow reads
them during `inspect-source`.

| Key | Written by | When | Value |
| --- | --- | --- | --- |
| `backend_hash` | `record-final-backend-cd-state` | `BACKEND_ONLY` or `FULL`, after backend build, backend CD tasks, and rollout reach a terminal state | SHA256 digest of all tracked files under `backend/` at the deployed commit. Computed in `inspect-source`. |
| `backend_image` | `record-final-backend-cd-state` | same as `backend_hash` | Full backend container image URI for the deployed commit: `{backend_image_repository_uri}:{commit-sha}`. |
| `frontend_hash` | `record-final-frontend-cd-state` | `FRONTEND_ONLY` or `FULL`, after frontend build/upload and CDN invalidation reach a terminal state | SHA256 digest of all tracked files under `frontend/` at the deployed commit. Computed in `inspect-source`. |
| `frontend_env_hash` | `record-final-frontend-cd-state` | same as `frontend_hash` | SHA256 digest of the frontend build-time env inputs used for change detection: baked-in identity/auth/API vars, `project_id`, and `frontend_env_vars` from `/workspace/terraform-outputs.json`. Computed in `inspect-source`. |

Example `data` after both backend and frontend have deployed successfully:

```yaml
data:
  backend_hash: "a1b2c3..."
  backend_image: "us-central1-docker.pkg.dev/my-project/my-repo/backend:abc123def456..."
  frontend_hash: "d4e5f6..."
  frontend_env_hash: "789abc..."
```

`inspect-source` compares current values against these keys to set
`backend-build-needed`, `backend-rollout-needed`, and `frontend-deploy-needed`.
Backend keys are updated independently of frontend keys, so a `BACKEND_ONLY`
run updates only `backend_hash` and `backend_image`, and a `FRONTEND_ONLY` run
updates only `frontend_hash` and `frontend_env_hash`.

## Backend CD Tasks

`backend_cd_tasks` defines ordered deployment-time backend tasks. The
`kubernetes_config` module passes this list into `cd_workflow` so backend
runtime resources and backend deployment tasks stay in the same Kubernetes
configuration boundary. The current environment roots configure a `migrations`
task through `kubernetes_config`, which runs:

```bash
python -m src.cd_tasks.run_alembic_migrations
```

The backend branch runs these tasks after the desired backend image exists and
before `backend-rollout`. Each task is created by Argo as a short-lived
Kubernetes Job in the backend namespace so it can use backend-local runtime
resources: the backend Kubernetes service account, `backend-env`, the
External Secrets-managed backend Secret, Cloud SQL Auth Proxy, and the GCS Fuse
bucket mount. This preserves the backend runtime access model without copying
secrets or env into the Argo namespace.

Backend CD tasks only run when the backend deployment leg runs. Adding or
changing a task definition is an infrastructure change; it does not itself
trigger a backend deployment. A newly added task will not run during the
`INFRA_ONLY` workflow that installs it. It runs on the next `BACKEND_ONLY` or
`FULL` workflow where the backend image needs rollout.

Backend task public internet egress currently follows the cluster's general GKE
egress path. Static allowlisted backend egress is intentionally separate from
this module.

## Calling The Workflow

External callers submit the installed `WorkflowTemplate` in the Argo namespace.
The caller should not pass environment configuration, cloud project IDs,
frontend build variables, Kubernetes object names, bucket names, or CDN names as
workflow parameters. Terraform wires those values into the template when this
module is applied.

Required workflow parameters:

| Parameter | Description |
| --- | --- |
| `source-auth-secret-name` | Name of a Kubernetes Secret in the workflow namespace. The Secret contains the temporary Git authentication material used by `clone-source`. |
| `commit-sha` | Full commit SHA to clone and deploy. The workflow checks out this exact commit. |
| `deployment-mode` | One of `INFRA_ONLY`, `BACKEND_ONLY`, `FRONTEND_ONLY`, or `FULL`. |

Deployment modes:

| Mode | Behavior |
| --- | --- |
| `INFRA_ONLY` | Clone the repo, run Terraform prepare/import/targeted plans and applies/full apply, write outputs, and push state. Backend and frontend deploy steps are skipped. |
| `BACKEND_ONLY` | Clone the repo, pull Terraform state, write Terraform outputs, inspect backend source state, build the backend image if needed, run backend CD tasks before rollout if the backend image is changing, update the backend Deployment if needed, and record only backend workflow state. Terraform plan/apply and frontend deploy steps are skipped. |
| `FRONTEND_ONLY` | Clone the repo, pull Terraform state, write Terraform outputs, inspect frontend source/env state, build/upload frontend assets if needed, invalidate CDN after upload, and record only frontend workflow state. Terraform plan/apply and backend deploy steps are skipped. |
| `FULL` | Run Terraform convergence first, then backend and frontend branches if their source/config state requires work. |

The caller creates the temporary source auth Secret before submitting the
workflow. The `delete-source-auth-secret` exit handler deletes that Secret at
the end of the run.

The Secret must contain:

| Key | Required | Description |
| --- | --- | --- |
| `authorization-header` | Yes | Complete HTTP authorization header for Git, such as `Authorization: Basic ...` or `Authorization: Bearer ...`. |

Provider examples:

```bash
# GitHub App installation token with Contents read permission.
BASIC_AUTH="$(printf '%s' "x-access-token:${GITHUB_INSTALLATION_TOKEN}" | base64 | tr -d '\n')"
kubectl -n argo create secret generic deploy-$RUN_ID-source-auth \
  --from-literal=authorization-header="Authorization: Basic $BASIC_AUTH"

# GitLab OAuth, project access, or group access token with read_repository.
BASIC_AUTH="$(printf '%s' "oauth2:${GITLAB_TOKEN}" | base64 | tr -d '\n')"
kubectl -n argo create secret generic deploy-$RUN_ID-source-auth \
  --from-literal=authorization-header="Authorization: Basic $BASIC_AUTH"

# GitLab deploy token with read_repository.
BASIC_AUTH="$(printf '%s' "${GITLAB_DEPLOY_USERNAME}:${GITLAB_DEPLOY_TOKEN}" | base64 | tr -d '\n')"
kubectl -n argo create secret generic deploy-$RUN_ID-source-auth \
  --from-literal=authorization-header="Authorization: Basic $BASIC_AUTH"

# Bitbucket OAuth or repository/project/workspace access token with repository read scope.
BASIC_AUTH="$(printf '%s' "x-token-auth:${BITBUCKET_TOKEN}" | base64 | tr -d '\n')"
kubectl -n argo create secret generic deploy-$RUN_ID-source-auth \
  --from-literal=authorization-header="Authorization: Basic $BASIC_AUTH"

# Azure DevOps Microsoft Entra token for Azure DevOps. The service principal or
# managed identity must already have Azure DevOps org/project/repository access.
kubectl -n argo create secret generic deploy-$RUN_ID-source-auth \
  --from-literal=authorization-header="Authorization: Bearer $AZURE_DEVOPS_ENTRA_TOKEN"
```

Submit from the installed `WorkflowTemplate`:

```bash
kubectl -n argo create -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: deploy-fullstack-template-
spec:
  workflowTemplateRef:
    name: deploy-fullstack-template
  arguments:
    parameters:
      - name: source-auth-secret-name
        value: deploy-$RUN_ID-source-auth
      - name: commit-sha
        value: $COMMIT_SHA
      - name: deployment-mode
        value: FULL
EOF
```

Watch the run:

```bash
kubectl -n argo get workflows
kubectl -n argo logs -f workflow/$WORKFLOW_NAME
```

`deployment-mode` is validated by the first workflow step. Invalid values fail
before Terraform, image build, rollout, upload, or CDN side effects run.
