locals {
  # ---- Identity & region ----------------------------------------------------
  project_name = "raintech"
  environment  = "prod"
  location     = "southeastasia"

  # ---- Governance tags (merged onto every resource by each module) ----------
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "raintech-team"
    Application = "rian-raintech-appsvc"
  }

  # ---- Static, globally-unique resource names -------------------------------
  app_name        = "raintech-prod-app-rse01"
  sql_server_name = "raintech-prod-sql-rse01"
  key_vault_name  = "raintech-prod-kv-rse01"

  # ---- App Service ----------------------------------------------------------
  # Plan name = {project}-{env}-plan-01; app name = local.app_name
  app = {
    service_plan_sku  = "F1"
    node_version      = "24-lts"
    health_check_path = "/healthz"
  }

  # ---- Database (Azure SQL, free serverless offer) --------------------------
  # Server name = local.sql_server_name; database = <name>
  database = {
    name                        = "appdb"
    entra_admin_login           = "sql-entra-admin"
    sku_name                    = "GP_S_Gen5_2"
    max_size_gb                 = 3
    min_capacity                = 0.5
    auto_pause_delay_in_minutes = 60
    use_free_limit              = false
  }

  # ---- Monitoring / Logs ----------------------------------------------------
  # Resulting names: workspace = {project}-{env}-log-01, action group = {project}-{env}-ag-01
  monitoring = {
    log_retention_days = 30
    daily_quota_gb     = 0.5
  }

  # ---- Alert catalogue (declarative) ----------------------------------------
  metric_alerts = {
    "cpu-high" = {
      description      = "App Service Plan CPU above 80% (sustained)"
      target           = "plan"
      metric_namespace = "Microsoft.Web/serverfarms"
      metric_name      = "CpuPercentage"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 80
      severity         = 2
      frequency        = "PT5M"
      window_size      = "PT15M"
    }
    "http-5xx" = {
      description      = "Web app returning 5xx server errors"
      target           = "app"
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "Http5xx"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 10
      severity         = 1
      frequency        = "PT1M"
      window_size      = "PT5M"
    }
    "http-4xx" = {
      description      = "Elevated 4xx client errors (bad requests / auth / 404s)"
      target           = "app"
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "Http4xx"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 50
      severity         = 3
      frequency        = "PT5M"
      window_size      = "PT15M"
    }
    "response-time-high" = {
      description      = "Slow responses — average latency above 3s"
      target           = "app"
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "HttpResponseTime" # unit: seconds
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 3
      severity         = 2
      frequency        = "PT1M"
      window_size      = "PT5M"
    }
    "memory-high" = {
      description      = "App memory working set above ~450 MiB"
      target           = "app"
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "MemoryWorkingSet" # unit: bytes
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 471859200 # 450 * 1024 * 1024
      severity         = 2
      frequency        = "PT5M"
      window_size      = "PT15M"
    }
    "health-check-unhealthy" = {
      description      = "Health check reporting unhealthy instances (/healthz)"
      target           = "app"
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "HealthCheckStatus" # 100 = healthy; <100 = an instance is failing
      aggregation      = "Average"
      operator         = "LessThan"
      threshold        = 100
      severity         = 1
      frequency        = "PT5M"
      window_size      = "PT15M"
    }
  }
}
