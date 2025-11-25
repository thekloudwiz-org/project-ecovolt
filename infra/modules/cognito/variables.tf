# Cognito Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_mfa" {
  description = "Enable MFA for customer user pool"
  type        = bool
  default     = false
}

variable "enable_advanced_security" {
  description = "Enable advanced security features (compromised credentials detection)"
  type        = bool
  default     = true
}

variable "create_separate_admin_pool" {
  description = "Create a separate user pool for admins (recommended for production)"
  type        = bool
  default     = false
}

variable "create_identity_pool" {
  description = "Create Cognito Identity Pool for AWS resource access"
  type        = bool
  default     = false
}

variable "mobile_app_callback_urls" {
  description = "Callback URLs for mobile app OAuth"
  type        = list(string)
  default     = ["ecovolt://callback"]
}

variable "mobile_app_logout_urls" {
  description = "Logout URLs for mobile app OAuth"
  type        = list(string)
  default     = ["ecovolt://logout"]
}

variable "admin_portal_callback_urls" {
  description = "Callback URLs for admin portal OAuth"
  type        = list(string)
  default     = ["https://admin.ecovolt.thekloudwiz.com/callback"]
}

variable "admin_portal_logout_urls" {
  description = "Logout URLs for admin portal OAuth"
  type        = list(string)
  default     = ["https://admin.ecovolt.thekloudwiz.com/logout"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
