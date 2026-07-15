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

variable "retention_in_days" {
  description = "Log retention in days (30 is the free minimum)"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB. Protects the ~5 GB/month free grant. -1 = unlimited."
  type        = number
  default     = 0.5
}
