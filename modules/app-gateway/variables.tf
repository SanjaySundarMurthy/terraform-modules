variable "app_gateway_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "waf_mode" {
  description = "WAF mode: Detection or Prevention"
  type        = string
  default     = "Prevention"
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 10
}

variable "backend_pools" {
  type = list(object({
    name         = string
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
}

variable "backend_http_settings" {
  type = list(object({
    name            = string
    port            = number
    protocol        = string
    cookie_affinity = optional(string, "Disabled")
    request_timeout = optional(number, 30)
    probe_name      = optional(string)
  }))
}

variable "health_probes" {
  type = list(object({
    name                = string
    protocol            = string
    path                = string
    host                = optional(string)
    interval            = optional(number, 30)
    timeout             = optional(number, 30)
    unhealthy_threshold = optional(number, 3)
  }))
  default = []
}

variable "ssl_certificate_name" {
  type    = string
  default = null
}

variable "ssl_key_vault_secret_id" {
  type    = string
  default = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
