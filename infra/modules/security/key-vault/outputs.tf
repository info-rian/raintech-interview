output "id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Key Vault base URI"
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_uris" {
  description = "Map of secret name => versionless secret URI (for App Service Key Vault references)"
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.versionless_id }
}
