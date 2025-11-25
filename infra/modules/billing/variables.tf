# Billing Module - Variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "overall_monthly_budget" {
  description = "Overall monthly budget limit in USD"
  type        = number

  validation {
    condition     = var.overall_monthly_budget > 0
    error_message = "Overall monthly budget must be greater than 0."
  }
}

variable "budget_alert_email_addresses" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
}

variable "budget_alert_phone_numbers" {
  description = "List of phone numbers for SMS budget alerts (E.164 format)"
  type        = list(string)
  default     = []
}

variable "budget_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [80, 90, 100]

  validation {
    condition     = alltrue([for t in var.budget_thresholds : t > 0 && t <= 100])
    error_message = "Budget thresholds must be between 0 and 100."
  }
}

variable "enable_forecasted_alerts" {
  description = "Enable forecasted budget alerts"
  type        = bool
  default     = true
}

variable "service_budgets" {
  description = "Service-specific budget limits in USD"
  type = object({
    compute   = number
    storage   = number
    database  = number
    iot       = number
    transfer  = number
    analytics = number
  })
  default = {
    compute   = 0
    storage   = 0
    database  = 0
    iot       = 0
    transfer  = 0
    analytics = 0
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
