locals {
  aks_container_insights_streams = [
    "Microsoft-ContainerLogV2",
    "Microsoft-KubeEvents",
    "Microsoft-KubePodInventory",
  ]

  aks_control_plane_log_categories = [
    "kube-apiserver",
    "kube-audit",
    "kube-audit-admin",
    "kube-controller-manager",
    "kube-scheduler",
    "cluster-autoscaler",
    "guard",
  ]
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${local.name_prefix}-aks-logs"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule" "aks_container_insights" {
  name                = "MSCI-${azurerm_resource_group.default.location}-${module.aks.cluster_name}"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  kind                = "Linux"
  description         = "DCR for Azure Monitor Container Insights."

  destinations {
    log_analytics {
      name                  = "ciworkspace"
      workspace_resource_id = azurerm_log_analytics_workspace.aks.id
    }
  }

  data_flow {
    streams      = local.aks_container_insights_streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = local.aks_container_insights_streams
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          namespaces             = []
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule_association" "aks_container_insights" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = module.aks.cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks_container_insights.id
  description             = "Association of the Container Insights data collection rule with the AKS cluster."
}

resource "azurerm_monitor_diagnostic_setting" "aks_control_plane" {
  name                           = "${local.name_prefix}-aks-control-plane-logs"
  target_resource_id             = module.aks.cluster_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.aks.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(local.aks_control_plane_log_categories)

    content {
      category = enabled_log.value
    }
  }
}
