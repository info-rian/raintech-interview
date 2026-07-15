# Module: monitoring/alerts
# Creates: azurerm_monitor_action_group + azurerm_monitor_metric_alert (for_each)
#          + azurerm_monitor_diagnostic_setting
# Kind:    monitoring
#
# The metric_alerts map is the scalable surface: add a map entry in the env root
# and a new alert appears — no changes to this module.

locals {
  ag_name = "${var.project_name}-${var.environment}-ag-01"

  # Resolve each alert's scope from its declared target.
  scope_for = {
    app  = var.web_app_id
    plan = var.service_plan_id
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = local.ag_name
  resource_group_name = var.resource_group_name
  short_name          = substr("${var.project_name}${var.environment}", 0, 12)

  email_receiver {
    name                    = "ops-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = merge(
    var.tags,
    {
      Name        = local.ag_name
      Kind        = "monitoring"
      Environment = var.environment
    }
  )
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts

  name                = "${var.project_name}-${var.environment}-alert-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [local.scope_for[each.value.target]]
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-alert-${each.key}"
      Kind        = "monitoring"
      Environment = var.environment
    }
  )
}

# Ship the web app's logs + metrics to Log Analytics (keeps within the free grant
# via the workspace daily_quota_gb cap).
resource "azurerm_monitor_diagnostic_setting" "web_app" {
  name                       = "${var.project_name}-${var.environment}-diag-app"
  target_resource_id         = var.web_app_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.diagnostic_log_categories)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
