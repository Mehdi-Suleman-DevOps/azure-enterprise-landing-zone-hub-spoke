variable "resource_group_name" { type = string }
variable "vnet_ids" {
  type        = map(string)
  description = "Map of VNet keys to VNet IDs for DNS linking."
}
variable "tags" { type = map(string); default = {} }
