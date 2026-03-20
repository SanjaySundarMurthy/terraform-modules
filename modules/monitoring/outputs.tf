output "workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "workspace_customer_id" {
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "app_insights_id" {
  value = var.enable_app_insights ? azurerm_application_insights.this[0].id : null
}

output "app_insights_instrumentation_key" {
  value     = var.enable_app_insights ? azurerm_application_insights.this[0].instrumentation_key : null
  sensitive = true
}

output "app_insights_connection_string" {
  value     = var.enable_app_insights ? azurerm_application_insights.this[0].connection_string : null
  sensitive = true
}
