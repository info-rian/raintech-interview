# Module: web/app-service
# Creates: azurerm_service_plan (Linux) + azurerm_linux_web_app
#          (+ optional custom-domain managed certificate)
# Kind:    compute
#
# Free tier (F1): always_on is not supported and must be false. HTTPS is enforced
# on the built-in *.azurewebsites.net certificate. A system-assigned managed
# identity lets the app read Key Vault references without stored credentials.

locals {
  plan_name = "${var.project_name}-${var.environment}-plan-01"
  app_name  = var.app_name
  is_free   = contains(["F1", "FREE", "Free"], var.service_plan_sku)
}

resource "azurerm_service_plan" "this" {
  name                = local.plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku

  tags = merge(
    var.tags,
    {
      Name        = local.plan_name
      Kind        = "compute"
      Environment = var.environment
    }
  )
}

resource "azurerm_linux_web_app" "this" {
  name                = local.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only = var.https_only

  identity {
    type = "SystemAssigned"
  }

  site_config {
    # always_on is unavailable on Free/Shared; force off there.
    always_on         = local.is_free ? false : true
    health_check_path = var.health_check_path
    # Provider requires the eviction time whenever a health_check_path is set.
    health_check_eviction_time_in_min = var.health_check_path != "" ? var.health_check_eviction_time_in_min : null
    minimum_tls_version               = var.minimum_tls_version
    ftps_state                        = "Disabled"
    app_command_line                  = var.app_command_line

    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = var.app_settings

  tags = merge(
    var.tags,
    {
      Name        = local.app_name
      Kind        = "compute"
      Environment = var.environment
    }
  )

  lifecycle {
    # The deploy pipeline writes these at release time; Terraform shouldn't revert them.
    ignore_changes = [
      app_settings["APP_COMMIT_SHA"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# ---- Optional: custom domain + free managed certificate (requires B1+) ------
resource "azurerm_app_service_custom_hostname_binding" "this" {
  count               = var.enable_managed_certificate ? 1 : 0
  hostname            = var.custom_domain
  app_service_name    = azurerm_linux_web_app.this.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_app_service_managed_certificate" "this" {
  count                      = var.enable_managed_certificate ? 1 : 0
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[0].id
}

resource "azurerm_app_service_certificate_binding" "this" {
  count               = var.enable_managed_certificate ? 1 : 0
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[0].id
  certificate_id      = azurerm_app_service_managed_certificate.this[0].id
  ssl_state           = "SniEnabled"
}
