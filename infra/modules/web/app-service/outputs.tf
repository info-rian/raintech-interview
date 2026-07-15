output "id" {
  description = "Web app resource ID"
  value       = azurerm_linux_web_app.this.id
}

output "name" {
  description = "Web app name"
  value       = azurerm_linux_web_app.this.name
}

output "service_plan_id" {
  description = "App Service plan resource ID (target for CPU alerts)"
  value       = azurerm_service_plan.this.id
}

output "default_hostname" {
  description = "Default *.azurewebsites.net hostname"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "url" {
  description = "Public HTTPS URL of the app"
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "principal_id" {
  description = "System-assigned managed identity principal ID (for Key Vault RBAC)"
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
