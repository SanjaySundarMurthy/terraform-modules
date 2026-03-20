terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
  }
}

resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"
  public_network_access_enabled = var.public_network_access

  administrator_login                 = var.administrator_login
  administrator_login_password         = var.administrator_login_password

  azuread_administrator {
    login_username              = var.ad_admin_login
    object_id                   = var.ad_admin_object_id
    azuread_authentication_only = var.azuread_authentication_only
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "this" {
  name                        = var.database_name
  server_id                   = azurerm_mssql_server.this.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb                 = var.max_size_gb
  sku_name                    = var.sku_name
  zone_redundant              = var.zone_redundant
  geo_backup_enabled          = true
  storage_account_type        = var.zone_redundant ? "Zone" : "Geo"

  short_term_retention_policy {
    retention_days           = var.short_term_retention_days
    backup_interval_in_hours = 12
  }

  long_term_retention_policy {
    weekly_retention  = var.ltr_weekly_retention
    monthly_retention = var.ltr_monthly_retention
    yearly_retention  = var.ltr_yearly_retention
    week_of_year      = 1
  }

  threat_detection_policy {
    state                      = "Enabled"
    email_addresses            = var.security_alert_emails
    retention_days             = 90
    disabled_alerts            = []
  }

  tags = var.tags
}

resource "azurerm_mssql_server_transparent_data_encryption" "this" {
  server_id = azurerm_mssql_server.this.id
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  server_id              = azurerm_mssql_server.this.id
  log_monitoring_enabled = true
  retention_in_days      = 90
}

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.this.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  tags = var.tags
}
