terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.node_count
    min_count           = var.default_node_pool.min_count
    max_count           = var.default_node_pool.max_count
    enable_auto_scaling = var.default_node_pool.min_count != null
    vnet_subnet_id      = var.vnet_subnet_id
    os_disk_size_gb     = var.default_node_pool.os_disk_size_gb
    os_disk_type        = "Managed"
    max_pods            = 110
    zones               = var.availability_zones

    node_labels = {
      "nodepool" = "system"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.enable_azure_rbac
    managed            = true
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    max_graceful_termination_sec     = 600
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = 0.5
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  azure_policy_enabled = var.enable_azure_policy

  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  enable_auto_scaling   = each.value.min_count != null
  vnet_subnet_id        = var.vnet_subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_type               = lookup(each.value, "os_type", "Linux")
  zones                 = var.availability_zones
  max_pods              = 110
  mode                  = lookup(each.value, "mode", "User")

  node_labels = lookup(each.value, "labels", {})
  node_taints = lookup(each.value, "taints", [])

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
