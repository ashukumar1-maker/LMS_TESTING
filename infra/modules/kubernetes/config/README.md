# Kubernetes Config

This module owns Kubernetes-level runtime configuration that should be uploaded
after a cluster exists. It uses the Kubernetes provider for typed workload
resources.

The shape follows `../int-ghostenvs/infra/modules/gke_kubernetes_resources`:
that module creates a workload namespace and uploads backend runtime config
through `backend-env` and `backend-secret-refs` ConfigMaps, then creates the
workload service account, External Secrets resources, runtime resources, and
code-deploy RBAC in the same Kubernetes configuration boundary.

External Secrets Operator, cert-manager, ingress-nginx, and their CRDs are
installed by `infra/modules/kubernetes/crds` before this module is planned. That
lets this module keep typed `kubernetes_manifest` resources for `SecretStore`,
`ExternalSecret`, and cert-manager resources.

Environment roots call this module after configuring Kubernetes through the
cluster output and after `module.kubernetes_crds` has installed required CRDs:

```hcl
module "kubernetes_config" {
  source = "../../modules/kubernetes/config"

  environment         = var.environment
  backend_namespace   = module.deployment.backend_kubernetes_namespace
  backend_env_vars    = module.deployment.backend_runtime_env_vars
  backend_secret_refs = module.deployment.backend_service_backend_secret_refs
  service_account_name = module.deployment.backend_kubernetes_service_account_name
  # Other workload, ingress, workflow, and identity inputs come from module.deployment.

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.kubernetes_crds]
}
```

The module stores Secret Manager secret names, not secret values, in the
`backend-secret-refs` ConfigMap. External Secrets resolves those names into the
runtime Kubernetes Secret.

The backend API is exposed through a portable nginx `Ingress` with a
cert-manager-managed TLS Secret. cert-manager uses HTTP-01 validation through
the `nginx` ingress class by default, so `api.<domain_name>` must resolve to
the static public IP assigned to the ingress-nginx controller `LoadBalancer`
service before certificate issuance can succeed.

This module also instantiates `../cd_workflow`. Keeping the CD workflow under
`kubernetes_config` means the workflow can use the backend namespace,
ConfigMaps, Secret name, Deployment name, service account, Cloud SQL mount, and
GCS mount from the same module that creates them. Environment roots should not
call `cd_workflow` directly.

Backend pods read ConfigMap and Secret values as environment variables, so
changes only take effect when pods restart. The Deployment template includes
checksums for backend config and Secret Manager refs to trigger rollouts when
those contracts change. The ExternalSecret target Secret name is hash-suffixed
from the same non-secret refs so new pods wait for the matching Kubernetes
Secret. Secret value refresh under the same Secret Manager refs is left to
External Secrets and Kubernetes.

External Secrets refreshes `backend-secrets` on its configured interval. This
module sets `refreshInterval` to `1h`, so Secret Manager version updates can take
up to about one hour to appear in the Kubernetes Secret unless an operator forces
a refresh:

```bash
kubectl -n backend annotate externalsecret backend-secrets force-sync="$(date +%s)" --overwrite
kubectl -n backend get externalsecret backend-secrets -o yaml | grep refreshTime
```

Because backend secrets are consumed as environment variables, pods also need to
restart before the application process reads refreshed values:

```bash
kubectl -n backend rollout restart deployment/backend
kubectl -n backend rollout status deployment/backend --timeout=600s
```

Backend container sizing defaults live here: CPU and memory requests/limits
default to `1000m` and `512Mi`, and HPA scales from 1 to 10 replicas at 70% CPU
or 80% memory utilization.

Namespace names should flow from the cluster contract through explicit
per-namespace inputs such as `backend_namespace`. Add explicit names for each
new namespace rather than introducing a generic namespace input.
