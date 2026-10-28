variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "route_table_name" { type = string }
variable "firewall_private_ip" { type = string }
variable "subnet_ids" {
  type = map(string)
  description = "Subnet IDs to associate with this UDR."
}
variable "tags" { type = map(string); default = {} }
