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

variable "key_vault_name" {
  description = "Globally-unique Key Vault name (3-24 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 chars: alphanumerics and hyphens, start with a letter, and not end with a hyphen."
  }
}

variable "tenant_id" {
  description = "Azure AD tenant ID that owns the vault"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard | premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention window in days (7-90). 7 eases teardown in non-prod."
  type        = number
  default     = 7
}

variable "deployer_object_id" {
  description = "Object ID of the principal running Terraform; granted Secrets Officer so it can write secrets."
  type        = string
}

variable "secrets" {
  description = "Map of secret name => value to store in the vault."
  type        = map(string)
  default     = {}
  sensitive   = true
}
