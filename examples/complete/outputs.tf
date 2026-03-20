output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_uri" {
  value = module.key_vault.key_vault_uri
}

output "sql_connection_string" {
  value     = module.sql.connection_string
  sensitive = true
}

output "log_analytics_workspace_id" {
  value = module.monitoring.workspace_id
}
