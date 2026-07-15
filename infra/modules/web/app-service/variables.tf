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

variable "app_name" {
  description = "Globally-unique web app name (-> <app_name>.azurewebsites.net)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 2-60 chars: lowercase letters, digits, and hyphens; must not start or end with a hyphen."
  }
}

variable "service_plan_sku" {
  description = "App Service plan SKU. F1 = Free tier."
  type        = string
  default     = "F1"
}

variable "node_version" {
  description = "Linux Node.js runtime version"
  type        = string
  default     = "20-lts"
}

variable "app_command_line" {
  description = "Startup command for the app (empty = let Oryx infer from package.json)"
  type        = string
  default     = "npm start"
}

variable "health_check_path" {
  description = "Path App Service pings for health (also monitored by alerts)"
  type        = string
  default     = "/healthz"
}

variable "health_check_eviction_time_in_min" {
  description = "Minutes an unhealthy instance is removed from load balancing (required by the provider when health_check_path is set)"
  type        = number
  default     = 2

  validation {
    condition     = var.health_check_eviction_time_in_min >= 2 && var.health_check_eviction_time_in_min <= 10
    error_message = "health_check_eviction_time_in_min must be between 2 and 10."
  }
}

variable "https_only" {
  description = "Redirect all HTTP traffic to HTTPS"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for inbound HTTPS"
  type        = string
  default     = "1.2"
}

variable "app_settings" {
  description = "App settings map (use @Microsoft.KeyVault(...) for secret references)"
  type        = map(string)
  default     = {}
}

# ---- Managed certificate (custom domain) — free-tier gated ------------------
# The free App Service Managed Certificate requires Basic (B1)+ and a custom
# domain, neither available on F1. Kept here, off by default, production-ready.
variable "enable_managed_certificate" {
  description = "Create a custom-domain binding + free managed certificate (requires B1+)"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain to bind when enable_managed_certificate = true"
  type        = string
  default     = ""
}
