terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.app_gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  count = var.enable_waf ? 1 : 0

  name                = "${var.app_gateway_name}-waf"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = ["1", "2", "3"]
  enable_http2        = true

  firewall_policy_id = var.enable_waf ? azurerm_web_application_firewall_policy.this[0].id : null

  sku {
    name = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier = var.enable_waf ? "WAF_v2" : "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_port {
    name = "http"
    port = 80
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = lookup(backend_address_pool.value, "fqdns", [])
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", [])
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                  = backend_http_settings.value.name
      cookie_based_affinity = lookup(backend_http_settings.value, "cookie_affinity", "Disabled")
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      request_timeout       = lookup(backend_http_settings.value, "request_timeout", 30)
      probe_name            = lookup(backend_http_settings.value, "probe_name", null)
    }
  }

  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                = probe.value.name
      protocol            = probe.value.protocol
      path                = probe.value.path
      host                = lookup(probe.value, "host", null)
      interval            = lookup(probe.value, "interval", 30)
      timeout             = lookup(probe.value, "timeout", 30)
      unhealthy_threshold = lookup(probe.value, "unhealthy_threshold", 3)
    }
  }

  # HTTP listener (redirect to HTTPS)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  # Default HTTPS listener
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_certificate_name
  }

  # HTTP to HTTPS redirect
  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-redirect-rule"
    priority                    = 100
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https"
  }

  request_routing_rule {
    name                       = "https-rule"
    priority                   = 200
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = var.backend_pools[0].name
    backend_http_settings_name = var.backend_http_settings[0].name
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificate_name != null ? [1] : []
    content {
      name                = var.ssl_certificate_name
      key_vault_secret_id = var.ssl_key_vault_secret_id
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.app_gateway_name}-diag"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}
