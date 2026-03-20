variable "server_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  description = "Database SKU: GP_S_Gen5_1, GP_Gen5_2, BC_Gen5_2, etc."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "max_size_gb" {
  type    = number
  default = 32
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "public_network_access" {
  type    = bool
  default = false
}

variable "ad_admin_login" {
  description = "Azure AD admin login name"
  type        = string
}

variable "ad_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
}

variable "administrator_login" {
  description = "SQL administrator login name"
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "SQL administrator login password"
  type        = string
  default     = null
  sensitive   = true
}

variable "azuread_authentication_only" {
  description = "Set to true to use only Azure AD authentication (no SQL auth)"
  type        = bool
  default     = true
}

variable "allow_azure_services" {
  type    = bool
  default = true
}

variable "short_term_retention_days" {
  type    = number
  default = 35
}

variable "ltr_weekly_retention" {
  type    = string
  default = "P4W"
}

variable "ltr_monthly_retention" {
  type    = string
  default = "P12M"
}

variable "ltr_yearly_retention" {
  type    = string
  default = "P5Y"
}

variable "security_alert_emails" {
  type    = list(string)
  default = []
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
