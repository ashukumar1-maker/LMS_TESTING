locals {
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "api_server" {
  name                 = "aks-api-server"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.api_server_subnet_cidr]

  delegation {
    name = "aks-api-server"

    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = "postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.postgres_subnet_cidr]

  delegation {
    name = "postgres-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "private-endpoints"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.default.name
  address_prefixes                  = [var.private_endpoint_subnet_cidr]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_public_ip" "backend" {
  name                = "${var.name_prefix}-backend-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}
