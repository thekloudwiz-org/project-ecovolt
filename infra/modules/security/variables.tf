# Security Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kms_key_admins" {
  description = "List of IAM principal ARNs for KMS key administration"
  type        = list(string)
  default     = []
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for API logging"
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (if not provided, will be auto-generated)"
  type        = string
  default     = ""
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3"
  type        = number
  default     = 90

  validation {
    condition     = var.cloudtrail_log_retention_days >= 1
    error_message = "CloudTrail log retention must be at least 1 day."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic rotation for KMS keys"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
