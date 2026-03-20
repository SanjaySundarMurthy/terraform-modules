output "registry_id" {
  description = "Container registry resource ID"
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Container registry name"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Container registry login server URL"
  value       = azurerm_container_registry.this.login_server
}
