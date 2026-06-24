# Azure AKS Module

Creates the Azure Kubernetes Service cluster used by Azure environments.

## Responsibilities

- Provisions a single AKS cluster with a managed system node pool.
- Enables AKS API Server VNet Integration on a delegated API server subnet.
- Supports creating the cluster with temporary public API access for bootstrap,
  then closing public access with Azure CLI after in-cluster CD is ready.
- Enables AKS OIDC issuer and Azure Workload Identity.
- Enables the AKS Azure Monitor Container Insights addon.
- Uses Azure CNI overlay networking on the caller-provided AKS subnet.
- Enables built-in CSI storage drivers, including the Blob CSI driver needed by
  the backend mounted-storage path.
- Uses a caller-provided user-assigned identity for the AKS control plane.

## Key Inputs

- `resource_group_name`, `location`: Azure placement for the cluster.
- `name_prefix`, `dns_prefix`: Cluster naming inputs from the deployment
  orchestrator.
- `node_resource_group_name`: Explicit short node resource group name for
  AKS-managed node resources.
- `aks_subnet_id`: Subnet ID created by `../network`.
- `api_server_subnet_id`: Delegated subnet ID used by API Server VNet
  Integration. The subnet must be delegated to
  `Microsoft.ContainerService/managedClusters`.
- `control_plane_identity_id`: User-assigned managed identity ID for the AKS
  control plane. API Server VNet Integration with a caller-provided VNet cannot
  use a system-assigned control plane identity because subnet permissions must
  exist before AKS creation.
- `log_analytics_workspace_id`: Log Analytics workspace where the AKS Azure
  Monitor addon sends Container Insights data.
- `public_cluster_enabled`: Creation-time bootstrap switch. When `true`, the
  cluster is initially reachable through the public AKS API endpoint so CRDs,
  Helm releases, Argo, and other bootstrap resources can be applied from a local
  workstation. Set this to `false` after bootstrap, but close the live cluster
  with Azure CLI rather than relying on Terraform to toggle the field.
- `node_count`, `min_node_count`, `max_node_count`, `node_vm_size`: Default node
  pool sizing. AzureTest currently defaults to `Standard_D4as_v7`.

## Outputs

- `cluster_name`, `cluster_location`, `cluster_id`: Cluster identifiers exposed
  through the Azure deployment module.
- `oidc_issuer_url`: Used by backend and CD modules to create federated identity
  credentials.
- `kubelet_identity_object_id`: Used by the deployment module to grant AKS pull
  access to ACR.

## Notes

This module only creates AKS. Kubernetes resources, Helm releases, ingress
controllers, and Argo workflow templates should live outside this module.

## API Server Access Lifecycle

AKS API Server VNet Integration allows Azure to toggle public/private API
access in place, but the AzureRM Terraform provider still models
`private_cluster_enabled`, `private_cluster_public_fqdn_enabled`, and
`private_dns_zone_id` as replacement-only fields. This module therefore ignores
changes to those three attributes while keeping `prevent_destroy = true` on the
cluster.

The intended flow is:

1. Create the cluster with `public_cluster_enabled = true` when local bootstrap
   access is needed.
2. Authenticate with `az aks get-credentials` and apply the Kubernetes bootstrap
   resources.
3. Flip the environment tfvar to `false` so configuration records the intended
   steady state.
4. Close public API access with Azure CLI:

   ```bash
   az aks update \
     --resource-group "<resource-group>" \
     --name "<cluster-name>" \
     --enable-private-cluster
   ```

After public access is closed, local `kubectl`, Terraform Kubernetes providers,
CI automation, and troubleshooting commands must run from inside the VNet, over
VPN/peering, through a VNet-connected agent, or through an Azure-supported
command path such as `az aks command invoke`.
