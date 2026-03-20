variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "account_tier" {
  description = "Account tier: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  type        = string
  default     = "ZRS"
}

variable "public_network_access" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "enable_change_feed" {
  type    = bool
  default = true
}

variable "soft_delete_retention_days" {
  type    = number
  default = 30
}

variable "network_default_action" {
  type    = string
  default = "Deny"
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "containers" {
  description = "List of blob containers to create"
  type        = list(string)
  default     = []
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = list(object({
    name                 = string
    prefix_match         = optional(list(string), [])
    tier_to_cool_days    = optional(number)
    tier_to_archive_days = optional(number)
    delete_after_days    = optional(number)
  }))
  default = []
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
