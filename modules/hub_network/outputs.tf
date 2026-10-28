output "vnet_id" { value = azurerm_virtual_network.hub.id }
output "vnet_name" { value = azurerm_virtual_network.hub.name }
output "firewall_subnet_id" { value = azurerm_subnet.firewall.id }
output "gateway_subnet_id" { value = azurerm_subnet.gateway.id }
output "bastion_subnet_id" { value = azurerm_subnet.bastion.id }
