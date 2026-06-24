# Multi-Cloud Terraform Modules

Terraform modules are organized around provider-specific deployment modules. Environment roots keep the root module name `deployment` for output compatibility, but source the provider implementation for their cloud directly.

## Layout

```text
infra/modules/
  kubernetes/
    config/
    crds/
    cd_workflow/
  gcp/
    cd_steps/
    deployment/
    backend/
    frontend/
    database/
    storage/
    dns/
    vpc/
    ci_cd/
    critical_alerting/
    access_canaries/
    bucket_for_tf_state/
    secret/
    gke/
  azure/
    aks/
    backend/
    ci_cd/
    database/
    deployment/
    dns/
    network/
    storage/
```

Existing environments keep the root module name `deployment` and source the provider-specific deployment module:

```hcl
module "deployment" {
  source = "../../modules/gcp/deployment"
}
```

AzureTest uses `source = "../../modules/azure/deployment"`. The `cloud`
variables remain declared in environment roots for compatibility with existing
`terraform.auto.tfvars` files, but they no longer select a shared module.

Use provider-specific account identifiers instead of a generic account variable:

```tfvars
gcp_project_id = "my-gcp-project"
```

```tfvars
azure_subscription_id = "00000000-0000-0000-0000-000000000000"
```

The Azure substrate is implemented for AzureTest with provider-specific modules
that mirror the GCP boundaries where practical. Azure-specific Kubernetes
workload manifests and CD workflow steps are still follow-up work.

Provider-specific child modules should stay under their provider folder. Shared
cross-cloud modules should only be introduced when the same Terraform code can
work for more than one provider without hiding provider-specific behavior or
requiring unrelated provider configuration.

Kubernetes and Helm resources should live at the environment root, matching the
`../int-ghostenvs` apply split. Shared Kubernetes modules live under
`infra/modules/kubernetes`; provider-specific CD workflow steps live under the
owning provider, such as `infra/modules/gcp/cd_steps` and future
`infra/modules/azure/cd_steps`. Cluster-specific
Terraform modules can expose portable outputs such as Kubernetes cluster name,
namespace, and service account names. Cloud-provider implementation details and
defaults should stay in the provider module that owns the corresponding
infrastructure.
