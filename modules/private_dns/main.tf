locals {
  dns_zones = [
    "privatelink.vaultcore.azure.net",
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net"
  ]
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(locals.dns_zones)
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_links" {
  for_each = {
    for pair in setproduct(locals.dns_zones, keys(var.vnet_ids)) :
    "${pair[0]}-${pair[1]}" => {
      zone_name = pair[0]
      vnet_key  = pair[1]
      vnet_id   = var.vnet_ids[pair[1]]
    }
  }

  name                  = "link-${each.value.vnet_key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value.zone_name].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false
}
