variable "resource_group_name" {
  type        = string
  default     = "rg-enterprise-network-prod-001"
  description = "Target Resource Group for the Landing Zone Network."
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Primary Azure region."
}

variable "tags" {
  type = map(string)
  default = {
    Architecture = "Hub-and-Spoke"
    Framework    = "Microsoft CAF"
    Environment  = "Production"
    ManagedBy    = "Terraform"
    Owner        = "Mehdi-Suleman-DevOps"
  }
}
