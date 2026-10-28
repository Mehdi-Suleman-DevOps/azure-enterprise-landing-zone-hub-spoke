output "hub_vnet_id" {
  value       = module.hub_network.vnet_id
  description = "Resource ID of the Hub VNet."
}

output "firewall_private_ip" {
  value       = module.firewall.firewall_private_ip
  description = "Private IP of Azure Firewall Premium (Next Hop for UDRs)."
}

output "spoke_app_vnet_id" {
  value       = module.spoke_app.vnet_id
  description = "Resource ID of the Spoke Application VNet."
}

output "spoke_shared_vnet_id" {
  value       = module.spoke_shared.vnet_id
  description = "Resource ID of the Spoke Shared Services VNet."
}
