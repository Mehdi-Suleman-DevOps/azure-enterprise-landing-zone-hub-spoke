# ==============================================================================
# AZURE ENTERPRISE LANDING ZONE: HUB-AND-SPOKE ROOT ORCHESTRATION
# Author: Mehdi Suleman | Senior DevSecOps & Enterprise Automation Engineer
# ==============================================================================

resource "azurerm_resource_group" "rg_network" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# 1. Central Hub Virtual Network
module "hub_network" {
  source                     = "./modules/hub_network"
  resource_group_name        = azurerm_resource_group.rg_network.name
  location                   = azurerm_resource_group.rg_network.location
  vnet_name                  = "vnet-hub-prod-001"
  address_space              = "10.100.0.0/16"
  gateway_subnet_prefix      = "10.100.0.0/24"
  firewall_subnet_prefix     = "10.100.1.0/24"
  bastion_subnet_prefix      = "10.100.2.0/24"
  dns_resolver_subnet_prefix = "10.100.3.0/24"
  tags                       = var.tags
}

# 2. Azure Firewall Premium with TLS & IDPS
module "firewall" {
  source              = "./modules/azure_firewall"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
  firewall_name       = "afw-hub-prod-001"
  subnet_id           = module.hub_network.firewall_subnet_id
  tags                = var.tags
}

# 3. Spoke 1: Application & Workload VNet
module "spoke_app" {
  source              = "./modules/spoke_network"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
  spoke_name          = "vnet-spoke-app-prod-001"
  address_space       = "10.101.0.0/16"
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  tags                = var.tags

  subnets = {
    "snet-app-gw"           = { cidr = "10.101.1.0/24" }
    "snet-aks-nodes"        = { cidr = "10.101.2.0/24" }
    "snet-private-endpoints"= { cidr = "10.101.3.0/24" }
  }
}

# 4. Spoke 2: Shared Management & CI/CD Runners VNet
module "spoke_shared" {
  source              = "./modules/spoke_network"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
  spoke_name          = "vnet-spoke-shared-prod-001"
  address_space       = "10.102.0.0/16"
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  tags                = var.tags

  subnets = {
    "snet-devops-runners" = { cidr = "10.102.1.0/24" }
    "snet-security-tools" = { cidr = "10.102.2.0/24" }
  }
}

# 5. Route Table: Force 0.0.0.0/0 Egress to Azure Firewall
module "spoke_app_udr" {
  source              = "./modules/route_table"
  resource_group_name = azurerm_resource_group.rg_network.name
  location            = azurerm_resource_group.rg_network.location
  route_table_name    = "rt-spoke-app-to-firewall"
  firewall_private_ip = module.firewall.firewall_private_ip
  tags                = var.tags

  subnet_ids = {
    "aks"       = module.spoke_app.subnet_ids["snet-aks-nodes"]
    "endpoints" = module.spoke_app.subnet_ids["snet-private-endpoints"]
  }
}

# 6. Centralized Private DNS Zones Linked to all VNets
module "private_dns" {
  source              = "./modules/private_dns"
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = var.tags

  vnet_ids = {
    "hub"          = module.hub_network.vnet_id
    "spoke-app"    = module.spoke_app.vnet_id
    "spoke-shared" = module.spoke_shared.vnet_id
  }
}
