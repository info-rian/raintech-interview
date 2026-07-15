# Module: monitoring/log-analytics
# Creates: azurerm_log_analytics_workspace
# Kind:    monitoring
#
# A daily_quota_gb cap keeps ingestion inside the free-tier grant (~5 GB/month).

locals {
  name = "${var.project_name}-${var.environment}-log-01"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = merge(
    var.tags,
    {
      Name        = local.name
      Kind        = "monitoring"
      Environment = var.environment
    }
  )
}
