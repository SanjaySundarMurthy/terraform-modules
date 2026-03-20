variable "workspace_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "retention_in_days" {
  type    = number
  default = 90
}

variable "daily_quota_gb" {
  type    = number
  default = -1
}

variable "enable_app_insights" {
  type    = bool
  default = true
}

variable "app_insights_name" {
  type    = string
  default = ""
}

variable "app_insights_type" {
  type    = string
  default = "web"
}

variable "alert_email_receivers" {
  type = list(object({
    name  = string
    email = string
  }))
  default = []
}

variable "enable_default_alerts" {
  type    = bool
  default = false
}

variable "alert_target_resource_ids" {
  type    = list(string)
  default = []
}

variable "cpu_alert_threshold" {
  type    = number
  default = 85
}

variable "memory_alert_threshold_bytes" {
  type    = number
  default = 1073741824
}

variable "tags" {
  type    = map(string)
  default = {}
}
