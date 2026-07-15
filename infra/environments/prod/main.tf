
data "azurerm_client_config" "current" {}

# ---- Foundation -------------------------------------------------------------
module "resource_group" {
  source = "../../modules/resource-group"

  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  tags         = local.common_tags
}

# ---- Monitoring sink --------------------------------------------------------
module "log_analytics" {
  source = "../../modules/monitoring/log-analytics"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  retention_in_days = local.monitoring.log_retention_days
  daily_quota_gb    = local.monitoring.daily_quota_gb
}

# ---- Database ---------------------------------------------------------------
module "mssql" {
  source = "../../modules/database/mssql"

  environment         = local.environment
  location            = local.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  server_name                 = local.sql_server_name
  entra_admin_login           = local.database.entra_admin_login
  entra_admin_object_id       = data.azurerm_client_config.current.object_id
  entra_admin_tenant_id       = data.azurerm_client_config.current.tenant_id
  database_name               = local.database.name
  sku_name                    = local.database.sku_name
  max_size_gb                 = local.database.max_size_gb
  min_capacity                = local.database.min_capacity
  auto_pause_delay_in_minutes = local.database.auto_pause_delay_in_minutes
  use_free_limit              = local.database.use_free_limit
}

# ---- Secrets ----------------------------------------------------------------
module "key_vault" {
  source = "../../modules/security/key-vault"

  environment         = local.environment
  location            = local.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  key_vault_name     = local.key_vault_name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  deployer_object_id = data.azurerm_client_config.current.object_id

  secrets = {}
}

# ---- Web app ----------------------------------------------------------------
module "app_service" {
  source = "../../modules/web/app-service"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  app_name          = local.app_name
  service_plan_sku  = local.app.service_plan_sku
  node_version      = local.app.node_version
  health_check_path = local.app.health_check_path

  app_settings = {
    SQL_SERVER                     = module.mssql.server_fqdn
    SQL_DATABASE                   = module.mssql.database_name
    APP_ENVIRONMENT                = local.environment
    APP_COMMIT_SHA                 = "bootstrap" # overwritten by the deploy pipeline
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"      # Oryx builds (npm install) on deploy
  }
}

resource "azurerm_role_assignment" "app_kv_secrets_user" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.app_service.principal_id
}

# ---- Alerts + diagnostics ---------------------------------------------------
module "alerts" {
  source = "../../modules/monitoring/alerts"

  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  alert_email                = var.alert_email
  web_app_id                 = module.app_service.id
  service_plan_id            = module.app_service.service_plan_id
  log_analytics_workspace_id = module.log_analytics.id
  metric_alerts              = local.metric_alerts
}
