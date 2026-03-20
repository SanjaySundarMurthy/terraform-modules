terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  count = var.enable_app_insights ? 1 : 0

  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = var.app_insights_type

  tags = var.tags
}

resource "azurerm_monitor_action_group" "critical" {
  count = length(var.alert_email_receivers) > 0 ? 1 : 0

  name                = "ag-critical-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "critical"

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "cpu_alert" {
  count = var.enable_default_alerts ? 1 : 0

  name                = "alert-high-cpu-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = var.alert_target_resource_ids
  description         = "Alert when CPU exceeds threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  dynamic "action" {
    for_each = length(var.alert_email_receivers) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.critical[0].id
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "memory_alert" {
  count = var.enable_default_alerts ? 1 : 0

  name                = "alert-high-memory-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = var.alert_target_resource_ids
  description         = "Alert when memory exceeds threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.memory_alert_threshold_bytes
  }

  dynamic "action" {
    for_each = length(var.alert_email_receivers) > 0 ? [1] : []
    content {
      action_group_id = azurerm_monitor_action_group.critical[0].id
    }
  }

  tags = var.tags
}
