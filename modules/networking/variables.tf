variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = can(regex("^vnet-", var.vnet_name))
    error_message = "VNet name must start with 'vnet-' prefix."
  }
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be provided."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name    = string
      service = string
    }))
  }))
  default = {}
}

variable "nsgs" {
  description = "Map of network security groups with rules"
  type = map(object({
    rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "Map of subnet name to NSG name"
  type        = map(string)
  default     = {}
}

variable "vnet_peerings" {
  description = "Map of VNet peering configurations"
  type = map(object({
    remote_vnet_id          = string
    allow_vnet_access       = optional(bool, true)
    allow_forwarded_traffic = optional(bool, false)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
