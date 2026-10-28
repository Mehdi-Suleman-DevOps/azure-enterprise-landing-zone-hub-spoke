resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.firewall_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "fw_policy" {
  name                = "${var.firewall_name}-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  threat_intelligence_mode = "AlertAndDeny"
  tags                = var.tags

  intrusion_detection {
    mode = "Deny"
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rules" {
  name               = "enterprise-rule-collection"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allow-ntp-and-dns"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }

  application_rule_collection {
    name     = "allow-whitelisted-egress"
    priority = 200
    action   = "Allow"

    rule {
      name             = "allow-package-registries"
      source_addresses = ["10.0.0.0/8"]

      protocols {
        type = "Https"
        port = 443
      }

      target_fqdns = [
        "*.docker.io",
        "*.github.com",
        "*.microsoft.com",
        "*.azure.com"
      ]
    }
  }
}

resource "azurerm_firewall" "fw" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}
