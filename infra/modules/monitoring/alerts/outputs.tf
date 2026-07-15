output "action_group_id" {
  description = "Action group resource ID"
  value       = azurerm_monitor_action_group.this.id
}

output "metric_alert_ids" {
  description = "Map of alert name => metric alert resource ID"
  value       = { for k, a in azurerm_monitor_metric_alert.this : k => a.id }
}

output "diagnostic_setting_id" {
  description = "Diagnostic setting resource ID"
  value       = azurerm_monitor_diagnostic_setting.web_app.id
}
