variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "spoke_name" { type = string }
variable "address_space" { type = string }
variable "hub_vnet_id" { type = string }
variable "hub_vnet_name" { type = string }
variable "subnets" {
  type = map(object({
    cidr = string
  }))
}
variable "tags" { type = map(string); default = {} }
