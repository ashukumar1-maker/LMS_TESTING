# Private GKE

The Terraform stack creates a private, VPC-native GKE cluster in the main app
VPC. Nodes do not receive external IP addresses. The control plane uses an
internal endpoint only, and deployment tooling uses GKE Fleet Connect Gateway
instead of routing directly to the private control plane IP.

This cluster is the active backend runtime. Deployment-time backend tasks run
through the Argo CD workflow instead of Cloud Run Jobs.

## Terraform Layout

GKE is split across GCP-specific modules behind the root `deployment` module.
Kubernetes-facing resources are called from the environment root:

- GCP environment roots source `infra/modules/gcp/deployment` as
  `module "deployment"` and use it as the non-Kubernetes infrastructure target
  for bootstrap.
- `infra/modules/gcp/vpc` creates a dedicated GKE node subnet and secondary
  ranges for pods and services.
- `infra/modules/gcp/gke` creates the cluster, node pool, Workload Identity
  setup, node Google service account, External Secrets Google service account,
  Fleet membership, and Connect Gateway outputs.
- `infra/modules/kubernetes/config` is the root-level module for backend
  namespace, ConfigMaps, External Secrets, workload, service, ingress, HPA,
  runtime resources, and the nested CD workflow module.
- `infra/modules/kubernetes/crds` installs Kubernetes extension controllers and
  CRDs, including External Secrets and Argo Workflows.
- `infra/modules/kubernetes/cd_workflow` creates the CD WorkflowTemplate,
  workflow state ConfigMap, and scoped task RBAC as a child of
  `infra/modules/kubernetes/config`.

Kubernetes-facing names needed by the GKE cluster, such as backend and External
Secrets namespaces and service accounts, are defaulted in `infra/modules/gcp/gke`
and exposed back through deployment outputs. Environment roots do not pass these
names through Terraform variables.

This mirrors the split in `../int-ghostenvs`: cluster infrastructure lives under
`infra/modules/gke`, while Kubernetes-level resources are called directly from
each environment root through `infra/modules/gke_kubernetes_resources`. This
repo intentionally does not wire Kubernetes or Helm providers into environment
roots through the GCP deployment module; each environment root wires
those providers through Connect Gateway and calls `kubernetes_config` directly.

Unlike `../int-ghostenvs`, this repo enables private GKE nodes to match the
private-cluster contract. The GKE subnet is attached to a separate Cloud NAT
that uses Google-managed ephemeral NAT IPs so private nodes can pull public
controller and chart images. This NAT is intentionally not the backend static
egress path. Selective static egress for the backend Kubernetes deployment is
tracked separately and should be implemented with a workload-specific design
instead of reusing the general cluster NAT.

The GKE CIDR defaults are intentionally different from `../int-ghostenvs`:

- node subnet: `10.2.0.0/24`
- pod secondary range: `10.4.0.0/14`
- service secondary range: `10.9.0.0/20`

Do not use `10.8.0.0/20` for the service range in this repo. The static backend
egress subnet defaults to `10.8.0.0/28`, so that range would overlap.

## Bootstrap And Argo Apply Flow

Cloud Build is no longer the steady-state deployment runner. First-time
bootstrap uses local/provisioning Terraform targets to create the cluster,
Kubernetes extensions, and workflow templates:

```bash
terraform apply -auto-approve -input=false \
  -target=module.deployment

terraform apply -auto-approve -input=false \
  -target=module.kubernetes_crds

terraform apply -auto-approve -input=false \
  -target=module.kubernetes_config
```

This ordering matters because typed `kubernetes_manifest` resources require CRDs
to exist before Terraform can plan them. After bootstrap, the Argo deployment
workflow clones the requested commit, pulls Terraform state and
`terraform.auto.tfvars` from the state bucket, runs targeted/full Terraform
plans, applies only when a plan has changes, builds and deploys only changed
artifacts, pushes state, and records successful hashes in the Argo workflow
state ConfigMap.

## Local Cluster Access

The GKE control plane uses a private endpoint, so direct credentials from
`gcloud container clusters get-credentials` may produce a kubeconfig that points
at an unroutable private IP from a laptop. Use Fleet Connect Gateway credentials
instead:

```bash
gcloud auth login
gcloud config set project <gcp-project-id>
gcloud auth application-default set-quota-project <gcp-project-id>
gcloud services enable connectgateway.googleapis.com --project <gcp-project-id>

gcloud container fleet memberships get-credentials <environment>-gke \
  --location global \
  --project <gcp-project-id> \
  --billing-project <gcp-project-id>

kubectl config current-context
kubectl get namespaces
```

## Deferred Work

Backend Kubernetes egress through a stable static allowlisted IP is deferred.
The general GKE Cloud NAT uses auto-allocated IPs for private node internet
access and should not be treated as the backend egress contract.
