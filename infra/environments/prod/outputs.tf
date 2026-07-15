output "app_url" {
  description = "Public HTTPS URL of the deployed web app"
  value       = module.app_service.url
}

output "app_name" {
  description = "App Service name (used by the deploy pipeline)"
  value       = module.app_service.name
}

output "resource_group_name" {
  description = "Resource group holding the stack"
  value       = module.resource_group.name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.key_vault.name
}

output "sql_server_fqdn" {
  description = "Azure SQL server FQDN"
  value       = module.mssql.server_fqdn
}

output "sql_database_name" {
  description = "Application database name"
  value       = module.mssql.database_name
}

output "app_principal_id" {
  description = "App Service managed identity object ID (grant it a contained SQL user — see scripts/grant-sql-access.sh)"
  value       = module.app_service.principal_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace customer GUID (for KQL queries)"
  value       = module.log_analytics.workspace_id
}
