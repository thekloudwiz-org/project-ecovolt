# Monitoring Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alarm_email_addresses" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "alarm_phone_numbers" {
  description = "List of phone numbers for SMS alarm notifications (E.164 format)"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard creation"
  type        = bool
  default     = true
}

# Lambda monitoring
variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
  default     = []
}

variable "lambda_error_threshold" {
  description = "Lambda error rate threshold (percentage)"
  type        = number
  default     = 5
}

variable "lambda_duration_threshold" {
  description = "Lambda duration threshold in milliseconds"
  type        = number
  default     = 10000
}

# API Gateway monitoring
variable "enable_api_gateway_monitoring" {
  description = "Enable API Gateway monitoring alarms"
  type        = bool
  default     = true
}

variable "api_gateway_id" {
  description = "API Gateway REST API ID to monitor"
  type        = string
  default     = ""
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name to monitor"
  type        = string
  default     = ""
}

variable "api_4xx_error_threshold" {
  description = "API Gateway 4xx error rate threshold (percentage)"
  type        = number
  default     = 10
}

variable "api_5xx_error_threshold" {
  description = "API Gateway 5xx error rate threshold (percentage)"
  type        = number
  default     = 5
}

variable "api_latency_threshold" {
  description = "API Gateway latency threshold in milliseconds"
  type        = number
  default     = 1000
}

# Database monitoring
variable "enable_database_monitoring" {
  description = "Enable database monitoring alarms"
  type        = bool
  default     = true
}

variable "db_instance_id" {
  description = "RDS instance identifier to monitor"
  type        = string
  default     = ""
}

variable "db_cpu_threshold" {
  description = "Database CPU utilization threshold (percentage)"
  type        = number
  default     = 80
}

variable "db_connections_threshold" {
  description = "Database connections threshold"
  type        = number
  default     = 80
}

variable "db_storage_threshold" {
  description = "Database storage utilization threshold (percentage)"
  type        = number
  default     = 85
}

# Kinesis monitoring
variable "kinesis_stream_name" {
  description = "Kinesis stream name to monitor"
  type        = string
  default     = ""
}

variable "kinesis_iterator_age_threshold" {
  description = "Kinesis iterator age threshold in milliseconds"
  type        = number
  default     = 60000
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
