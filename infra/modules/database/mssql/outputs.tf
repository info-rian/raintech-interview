output "server_id" {
  description = "SQL Server resource ID"
  value       = azurerm_mssql_server.this.id
}

output "server_fqdn" {
  description = "Fully-qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_name" {
  description = "Application database name"
  value       = azurerm_mssql_database.this.name
}

