output "server_id" {
  value = azurerm_mssql_server.this.id
}

output "server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_id" {
  value = azurerm_mssql_database.this.id
}

output "database_name" {
  value = azurerm_mssql_database.this.name
}

output "connection_string" {
  description = "ADO.NET connection string (without password)"
  value       = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.this.name};Authentication=Active Directory Default;"
}
