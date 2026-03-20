variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string

  validation {
    condition     = can(regex("^aks-", var.cluster_name))
    error_message = "Cluster name must start with 'aks-' prefix."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for the default node pool"
  type        = string
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    vm_size         = string
    node_count      = optional(number, 3)
    min_count       = optional(number, 3)
    max_count       = optional(number, 10)
    os_disk_size_gb = optional(number, 128)
  })
}

variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    vm_size         = string
    node_count      = optional(number, 1)
    min_count       = optional(number, 1)
    max_count       = optional(number, 5)
    os_disk_size_gb = optional(number, 128)
    os_type         = optional(string, "Linux")
    mode            = optional(string, "User")
    labels          = optional(map(string), {})
    taints          = optional(list(string), [])
  }))
  default = {}
}

variable "network_plugin" {
  description = "Network plugin: azure or kubenet"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy: azure, calico, or cilium"
  type        = string
  default     = "azure"
}

variable "outbound_type" {
  description = "Outbound routing method"
  type        = string
  default     = "loadBalancer"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "172.16.0.10"
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers"
  type        = bool
  default     = false
}

variable "enable_workload_identity" {
  description = "Enable workload identity (OIDC + federated credentials)"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
