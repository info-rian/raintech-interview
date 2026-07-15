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

variable "location" {
  description = "Azure region (e.g. japaneast, southeastasia)"
  type        = string
}
