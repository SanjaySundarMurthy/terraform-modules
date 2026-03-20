# ============================================
# Complete Azure Infrastructure Stack
# Uses all modules for a production AKS deployment
# ============================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "complete-example.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

locals {
  environment = "prod"
  location    = "eastus2"
  project     = "myapp"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Repository  = "terraform-modules"
  }

  resource_prefix = "${local.project}-${local.environment}"
}

# ─── Resource Group ──────────────────────────────────────────
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.resource_prefix}"
  location = local.location
  tags     = local.common_tags
}

# ─── Monitoring (deploy first for diagnostic settings) ───────
module "monitoring" {
  source = "../../modules/monitoring"

  workspace_name      = "log-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  retention_in_days   = 90
  enable_app_insights = true
  app_insights_name   = "appi-${local.resource_prefix}"
  environment         = local.environment
  tags                = local.common_tags
}

# ─── Networking ──────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  vnet_name           = "vnet-${local.resource_prefix}"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    snet-aks = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
    }
    snet-db = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
    snet-appgw = {
      address_prefixes = ["10.0.3.0/24"]
    }
    snet-pe = {
      address_prefixes = ["10.0.4.0/24"]
    }
  }

  nsgs = {
    "nsg-aks" = {
      rules = [
        {
          name                   = "allow-https-inbound"
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          destination_port_range = "443"
        }
      ]
    }
  }

  subnet_nsg_associations = {
    "snet-aks" = "nsg-aks"
  }

  tags = local.common_tags
}

# ─── Key Vault ───────────────────────────────────────────────
module "key_vault" {
  source = "../../modules/key-vault"

  key_vault_name             = "kv-${local.resource_prefix}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  allowed_subnet_ids         = [module.networking.subnet_ids["snet-aks"]]
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["snet-pe"]
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = local.common_tags
}

# ─── Container Registry ─────────────────────────────────────
module "acr" {
  source = "../../modules/container-registry"

  registry_name              = "cr${replace(local.resource_prefix, "-", "")}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  sku                        = "Premium"
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["snet-pe"]
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = local.common_tags
}

# ─── AKS Cluster ─────────────────────────────────────────────
module "aks" {
  source = "../../modules/aks-cluster"

  cluster_name               = "aks-${local.resource_prefix}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  kubernetes_version         = "1.29"
  vnet_subnet_id             = module.networking.subnet_ids["snet-aks"]
  log_analytics_workspace_id = module.monitoring.workspace_id

  default_node_pool = {
    vm_size    = "Standard_D4s_v5"
    node_count = 3
    min_count  = 3
    max_count  = 10
  }

  additional_node_pools = {
    workload = {
      vm_size    = "Standard_D8s_v5"
      node_count = 2
      min_count  = 2
      max_count  = 20
      labels     = { "workload" = "app" }
    }
  }

  tags = local.common_tags
}

# ─── Storage Account ────────────────────────────────────────
module "storage" {
  source = "../../modules/storage-account"

  storage_account_name       = "st${replace(local.resource_prefix, "-", "")}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  replication_type           = "ZRS"
  allowed_subnet_ids         = [module.networking.subnet_ids["snet-aks"]]
  containers                 = ["data", "backups", "logs"]
  log_analytics_workspace_id = module.monitoring.workspace_id

  lifecycle_rules = [
    {
      name               = "archive-old-logs"
      prefix_match       = ["logs/"]
      tier_to_cool_days  = 30
      tier_to_archive_days = 90
      delete_after_days  = 365
    }
  ]

  tags = local.common_tags
}

# ─── SQL Database ────────────────────────────────────────────
module "sql" {
  source = "../../modules/sql-database"

  server_name                = "sql-${local.resource_prefix}"
  database_name              = "db-${local.project}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = local.location
  sku_name                   = "GP_S_Gen5_2"
  ad_admin_login             = "sqladmin"
  ad_admin_object_id         = "00000000-0000-0000-0000-000000000000" # Replace with actual
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["snet-pe"]
  tags                       = local.common_tags
}
