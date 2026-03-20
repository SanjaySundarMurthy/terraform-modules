output "app_gateway_id" {
  value = azurerm_application_gateway.this.id
}

output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "waf_policy_id" {
  value = var.enable_waf ? azurerm_web_application_firewall_policy.this[0].id : null
}
