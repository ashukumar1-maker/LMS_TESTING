# CD Workflow Operations

The steady-state deployment path is an Argo `WorkflowTemplate` installed in the
cluster by Terraform. It replaces Cloud Build for infrastructure and application
deployment after the initial bootstrap creates the cluster, CRDs/controllers,
and workflow resources.

## Cluster Replacement Guardrail

The GKE cluster has Terraform `prevent_destroy = true` in addition to provider
level deletion protection. If a Terraform change would replace or destroy the
cluster, Terraform fails the plan/apply instead of deleting it.

This is intentional. The Kubernetes and Helm providers depend on the cluster
being reachable through Connect Gateway. Destroying the cluster during the same
apply would also remove the runtime that owns Argo, Kubernetes config, External
Secrets, backend workloads, and CD workflow resources.

Do not bypass this guardrail for normal changes. Intentional cluster replacement
should be handled as a migration:

1. Create a new cluster separately.
2. Point provider wiring and Connect Gateway access at the new cluster.
3. Apply CRDs/controllers and Kubernetes runtime resources to the new cluster.
4. Submit or re-install CD workflow resources on the new cluster.
5. Cut traffic over deliberately.
6. Retire the old cluster after workloads and state are confirmed.

## Kubernetes Charts And CRDs

Kubernetes chart upgrades are normal when they can be applied in place. The
current Terraform structure keeps CRDs/controllers in `module.kubernetes_crds`
and dependent runtime/workflow resources in later modules because typed custom
resources can only be planned after the API server knows their CRDs.

For chart or CRD changes, use this sequence:

```bash
terraform apply -target=module.kubernetes_crds
terraform apply
```

If a chart upgrade changes CRD schemas in a breaking way, Terraform may fail
during plan or apply while validating existing custom resources. In that case,
handle the upgrade as an explicit compatibility migration: update the controller
and CRDs first, adjust dependent resources to the new schema, then run a full
apply. Avoid bundling breaking CRD/controller changes with unrelated
application changes.

## CD Workflow Template Changes

Changing the CD workflow, such as adding a step, changing dependencies, or
moving a provider-specific step module, updates the Argo `WorkflowTemplate`
object in place. Terraform should patch that object; it should not reprovision
the cluster.

Running Workflows are created from the template version that existed when they
were submitted. Updating the `WorkflowTemplate` does not reliably change a
Workflow that is already running. New Workflow submissions use the updated
template.

For workflow changes:

1. Apply the Terraform change that updates `module.kubernetes_config`.
2. Submit a new Argo Workflow.
3. Verify the expected path with the relevant deployment mode:
   `INFRA_ONLY`, `BACKEND_ONLY`, `FRONTEND_ONLY`, or `FULL`.

This behavior is useful during CD development: a broken new workflow template
does not mutate a currently running deployment, but it will affect subsequent
submissions after the Terraform apply.

## Terraform From Inside Argo

The Argo deployment workflow runs Terraform in multiple steps over a shared
workflow PVC. The prepare step clones source, pulls state and
`terraform.auto.tfvars`, initializes Terraform, and writes the Terraform binary
into `/workspace/bin`. GCP runs on the Cloud SDK image and also copies the GKE
auth plugin into `/workspace/bin`; Azure runs on the Azure CLI image and uses
Azure Workload Identity plus OIDC environment variables.

State push is scheduled after Terraform step instances reach terminal states, including
failures, so the state bucket still receives the latest local state files when
possible. Backend and frontend-only modes still run Terraform output extraction
from pulled state so application steps can read current deployment values
without rewriting the workflow template.

For Azure, the workflow passes `azure_subscription_id` to both `pullstate.py`
and `pushstate.py`. Terraform running inside AKS sets
`TF_VAR_use_in_cluster_kubernetes_config=true`, so the Azure Kubernetes and Helm
providers use the workflow pod's service account credentials and can reach a
private AKS API server through the in-cluster Kubernetes service. External
workflow submitters still need their own private AKS access path, such as a
VNet-connected runner or Azure-supported command path.

## Provider-Specific Artifact Steps

The shared workflow delegates cloud API operations to provider step modules.
GCP uses Artifact Registry, GCS, and Cloud CDN steps. Azure uses ACR Tasks for
backend image builds, Azure Storage static website sync for frontend assets, and
an explicit no-op for CDN invalidation until Azure Front Door or custom-domain
delivery is implemented.

## Workspace PVC Scheduling

The deployment workflow uses one `ReadWriteOnce` workspace PVC. That access mode
is appropriate for the current template, but it means pods must mount the volume
from the same Kubernetes node when multiple workflow steps run concurrently.

To keep this reliable on multi-node clusters, `clone-source` acts as the
workspace anchor pod. It is labeled with `workspace-anchor=true`.
Every later template that mounts `/workspace` has required pod affinity to that
same workflow's anchor pod using `kubernetes.io/hostname` as the topology key.
This forces workspace-consuming pods onto the same node as `clone-source`.

Templates that do not mount the workspace, such as CDN invalidation, final state
recording, backend rollout, and source auth cleanup, do not use this affinity
and can schedule normally.

If the workflow later needs true cross-node parallel shared filesystem access,
switch the workspace strategy to either a `ReadWriteMany` storage class or Argo
artifacts instead of widening the current `ReadWriteOnce` PVC.
