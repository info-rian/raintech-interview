variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev | staging | prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Common tags merged onto every resource"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Resource group to create resources in"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "alert_email" {
  description = "Email address that receives alert notifications"
  type        = string
}

variable "web_app_id" {
  description = "Resource ID of the web app (scope for app-level alerts, e.g. Http5xx)"
  type        = string
}

variable "service_plan_id" {
  description = "Resource ID of the App Service plan (scope for plan-level alerts, e.g. CpuPercentage)"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace ID that receives the web app's diagnostic logs/metrics"
  type        = string
}

# Declarative alert catalogue. Add an alert = add a map entry (no resource edits).
# `target` selects the scope: "app" (web_app_id) or "plan" (service_plan_id).
variable "metric_alerts" {
  description = "Map of alert name => metric alert definition"
  type = map(object({
    description      = string
    target           = string # "app" | "plan"
    metric_namespace = string
    metric_name      = string
    aggregation      = string # Average | Total | Maximum | Minimum | Count
    operator         = string # GreaterThan | LessThan | ...
    threshold        = number
    severity         = number # 0 (critical) .. 4 (verbose)
    frequency        = string # ISO8601, e.g. PT1M
    window_size      = string # ISO8601, e.g. PT5M
  }))
  default = {}

  validation {
    condition     = alltrue([for a in var.metric_alerts : contains(["app", "plan"], a.target)])
    error_message = "each metric_alerts entry.target must be \"app\" or \"plan\"."
  }
}

variable "diagnostic_log_categories" {
  description = "App Service log categories to ship to Log Analytics"
  type        = list(string)
  default     = ["AppServiceHTTPLogs", "AppServiceConsoleLogs", "AppServiceAppLogs"]
}
