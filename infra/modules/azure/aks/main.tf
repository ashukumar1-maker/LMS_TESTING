locals {
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  node_resource_group = var.node_resource_group_name

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  private_cluster_enabled             = !var.public_cluster_enabled
  private_cluster_public_fqdn_enabled = var.public_cluster_enabled ? null : false
  private_dns_zone_id                 = var.public_cluster_enabled ? null : "System"

  api_server_access_profile {
    subnet_id                           = var.api_server_subnet_id
    virtual_network_integration_enabled = true
  }

  default_node_pool {
    name                        = "system"
    node_count                  = var.node_count
    vm_size                     = var.node_vm_size
    vnet_subnet_id              = var.aks_subnet_id
    auto_scaling_enabled        = true
    min_count                   = var.min_node_count
    max_count                   = var.max_node_count
    temporary_name_for_rotation = "syspooltmp"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }


  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.control_plane_identity_id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    # API Server VNet Integration supports toggling public/private access in Azure,
    # but the Terraform provider still models these fields as replacement-only.
    ignore_changes = [
      private_cluster_enabled,
      private_cluster_public_fqdn_enabled,
      private_dns_zone_id,
    ]
  }
}
