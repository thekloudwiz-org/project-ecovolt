# DynamoDB Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

# Provisioned capacity settings (only used if billing_mode = "PROVISIONED")
variable "stations_read_capacity" {
  description = "Read capacity units for stations table"
  type        = number
  default     = 5
}

variable "stations_write_capacity" {
  description = "Write capacity units for stations table"
  type        = number
  default     = 5
}

variable "users_read_capacity" {
  description = "Read capacity units for user profiles table"
  type        = number
  default     = 5
}

variable "users_write_capacity" {
  description = "Write capacity units for user profiles table"
  type        = number
  default     = 5
}

variable "vehicle_status_read_capacity" {
  description = "Read capacity units for vehicle status table"
  type        = number
  default     = 10
}

variable "vehicle_status_write_capacity" {
  description = "Write capacity units for vehicle status table"
  type        = number
  default     = 10
}

variable "battery_read_capacity" {
  description = "Read capacity units for battery inventory table"
  type        = number
  default     = 5
}

variable "battery_write_capacity" {
  description = "Write capacity units for battery inventory table"
  type        = number
  default     = 5
}

variable "swap_events_read_capacity" {
  description = "Read capacity units for swap events table"
  type        = number
  default     = 5
}

variable "swap_events_write_capacity" {
  description = "Write capacity units for swap events table"
  type        = number
  default     = 10
}

variable "gsi_read_capacity" {
  description = "Read capacity units for GSIs"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "Write capacity units for GSIs"
  type        = number
  default     = 5
}

# Auto-scaling settings
variable "enable_autoscaling" {
  description = "Enable auto-scaling for provisioned capacity"
  type        = bool
  default     = false
}

variable "autoscaling_max_read_capacity" {
  description = "Maximum read capacity for auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_max_write_capacity" {
  description = "Maximum write capacity for auto-scaling"
  type        = number
  default     = 100
}

# Backup and recovery
variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for tables"
  type        = bool
  default     = true
}

# TTL settings
variable "enable_vehicle_status_ttl" {
  description = "Enable TTL for vehicle status table (auto-delete old records)"
  type        = bool
  default     = false
}

variable "enable_swap_events_ttl" {
  description = "Enable TTL for swap events table (auto-delete old records)"
  type        = bool
  default     = true
}

# Encryption
variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
}

# Monitoring
variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
