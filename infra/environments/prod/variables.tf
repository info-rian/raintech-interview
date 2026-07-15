# Root inputs. Non-secret configuration lives in locals.tf; secrets and the
# subscription target are variables so they come from tfvars / pipeline secrets.

variable "subscription_id" {
  description = "Target Azure subscription ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a 36-character GUID."
  }
}

variable "alert_email" {
  description = "Email address that receives Azure Monitor alerts"
  type        = string
}
