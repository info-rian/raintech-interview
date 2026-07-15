
locals {
  name = var.key_vault_name
}

resource "azurerm_key_vault" "this" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = var.soft_delete_retention_days

  public_network_access_enabled = true

  tags = merge(
    var.tags,
    {
      Name        = local.name
      Kind        = "security"
      Environment = var.environment
    }
  )
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

resource "azurerm_key_vault_secret" "this" {
  # Secret *names* are not sensitive (only the values are), so we can safely use
  # them as for_each keys; the sensitive value is read into the `value` attribute.
  for_each = nonsensitive(toset(keys(var.secrets)))

  name         = each.key
  value        = var.secrets[each.key]
  key_vault_id = azurerm_key_vault.this.id

  # Secret writes require the RBAC role above to have propagated.
  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}
