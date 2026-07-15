locals {
  server_name = var.server_name
  db_name     = var.database_name
}

resource "azurerm_mssql_server" "this" {
  name                         = local.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.azuread_authentication_only ? null : var.administrator_login
  administrator_login_password = var.azuread_authentication_only ? null : var.administrator_password
  minimum_tls_version          = "1.2"

  public_network_access_enabled = true

  # Entra ID admin. With azuread_authentication_only = true, SQL password auth is
  # disabled outright — the app connects with its managed identity, so there is
  # no credential to store in Key Vault or rotate.
  azuread_administrator {
    login_username              = var.entra_admin_login
    object_id                   = var.entra_admin_object_id
    tenant_id                   = var.entra_admin_tenant_id
    azuread_authentication_only = var.azuread_authentication_only
  }

  tags = merge(
    var.tags,
    {
      Name        = local.server_name
      Kind        = "database"
      Environment = var.environment
    }
  )
}

resource "azurerm_mssql_database" "this" {
  name      = local.db_name
  server_id = azurerm_mssql_server.this.id

  sku_name                    = var.sku_name
  min_capacity                = var.min_capacity
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  max_size_gb                 = var.max_size_gb
  zone_redundant              = false
  storage_account_type        = "Local" # cheapest backup redundancy

  tags = merge(
    var.tags,
    {
      Name        = local.db_name
      Kind        = "database"
      Environment = var.environment
    }
  )
}

# Allow other Azure services (App Service outbound IPs are dynamic) to reach the
# server. The 0.0.0.0 sentinel rule is Azure's "Allow Azure services" toggle.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "extra" {
  for_each = var.extra_firewall_ips

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azapi_update_resource" "free_limit" {
  count = var.use_free_limit ? 1 : 0

  type        = "Microsoft.Sql/servers/databases@2023-08-01-preview"
  resource_id = azurerm_mssql_database.this.id

  body = {
    properties = {
      useFreeLimit                = true
      freeLimitExhaustionBehavior = "AutoPause"
    }
  }
}
