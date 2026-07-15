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

variable "server_name" {
  description = "Globally-unique Azure SQL logical server name (-> <server_name>.database.windows.net)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.server_name))
    error_message = "server_name must be 1-63 chars: lowercase letters, digits, and hyphens; must not start or end with a hyphen."
  }
}

variable "administrator_login" {
  description = "SQL-auth admin username. Ignored when azuread_authentication_only = true."
  type        = string
  default     = null
}

variable "administrator_password" {
  description = "SQL-auth admin password. Ignored when azuread_authentication_only = true."
  type        = string
  sensitive   = true
  default     = null
}

# ---- Entra ID (Azure AD) authentication ------------------------------------
variable "entra_admin_login" {
  description = "Display-name label for the Entra ID administrator of the SQL server"
  type        = string
}

variable "entra_admin_object_id" {
  description = "Object ID of the Entra principal (user/group/SP) that administers the server"
  type        = string
}

variable "entra_admin_tenant_id" {
  description = "Tenant ID for the Entra administrator (defaults to the server's tenant)"
  type        = string
  default     = null
}

variable "azuread_authentication_only" {
  description = "Disable SQL password auth entirely — connections use Entra ID only (no password to store or rotate)"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "appdb"
}

variable "sku_name" {
  description = "Database SKU. GP_S_Gen5_2 is General Purpose serverless (free-offer eligible)."
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "max_size_gb" {
  description = "Max database size in GB (free offer includes up to 32 GB)"
  type        = number
  default     = 32
}

variable "min_capacity" {
  description = "Serverless minimum vCores"
  type        = number
  default     = 0.5
}

variable "auto_pause_delay_in_minutes" {
  description = "Idle minutes before the serverless DB auto-pauses (-1 disables)"
  type        = number
  default     = 60
}

variable "use_free_limit" {
  description = "Enable the Azure SQL Database free offer (100k vCore-seconds/month)"
  type        = bool
  default     = true
}

variable "extra_firewall_ips" {
  description = "Map of rule name => single IP to allow (e.g. an operator's IP)"
  type        = map(string)
  default     = {}
}
