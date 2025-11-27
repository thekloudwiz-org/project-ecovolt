# Compute Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Lambda security groups"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC-enabled Lambda functions"
  type        = list(string)
}

variable "lambda_runtime" {
  description = "Lambda runtime environment"
  type        = string
  default     = "python3.11"

  validation {
    condition     = contains(["python3.9", "python3.10", "python3.11", "python3.12", "nodejs18.x", "nodejs20.x"], var.lambda_runtime)
    error_message = "Lambda runtime must be a supported version."
  }
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for Lambda functions"
  type        = bool
  default     = true
}

variable "lambda_log_retention_days" {
  description = "CloudWatch Logs retention period for Lambda functions"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.lambda_log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

# variable "enable_waf_logging" {
#   description = "Enable WAF logging (requires Kinesis Firehose - adds cost)"
#   type        = bool
#   default     = false
# }

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 256

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 MB and 10240 MB."
  }
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_reserved_concurrent_executions" {
  description = "Reserved concurrent executions for critical Lambda functions (0 = unreserved)"
  type        = number
  default     = 0

  validation {
    condition     = var.lambda_reserved_concurrent_executions >= 0
    error_message = "Reserved concurrent executions must be >= 0."
  }
}

# API Gateway Configuration
variable "api_gateway_name" {
  description = "Name for API Gateway REST API"
  type        = string
  default     = "ecovolt-api"
}

variable "api_gateway_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "v1"
}

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000

  validation {
    condition     = var.api_gateway_throttle_burst_limit >= 0
    error_message = "Throttle burst limit must be >= 0."
  }
}

variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000

  validation {
    condition     = var.api_gateway_throttle_rate_limit >= 0
    error_message = "Throttle rate limit must be >= 0."
  }
}

variable "enable_api_gateway_access_logs" {
  description = "Enable API Gateway access logs"
  type        = bool
  default     = true
}

variable "enable_api_gateway_execution_logs" {
  description = "Enable API Gateway execution logs"
  type        = bool
  default     = true
}

# Database Configuration (for Lambda functions)
variable "db_endpoint" {
  description = "RDS database endpoint for Lambda functions"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name for Lambda functions"
  type        = string
  default     = ""
}

variable "db_security_group_id" {
  description = "Database security group ID (Lambda will be added to this SG)"
  type        = string
  default     = ""
}

# Kinesis Configuration (for stream processing Lambda)
variable "kinesis_stream_arn" {
  description = "Kinesis stream ARN for stream processing Lambda"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Cognito Integration
variable "enable_cognito_authorizer" {
  description = "Enable Cognito authorizer for API Gateway"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arn" {
  description = "ARN of Cognito User Pool for API Gateway authorizer"
  type        = string
  default     = ""
}

# DynamoDB Integration
variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs for Lambda access"
  type        = list(string)
  default     = []
}

variable "dynamodb_stream_arns" {
  description = "List of DynamoDB stream ARNs for Lambda triggers"
  type        = list(string)
  default     = []
}

variable "dynamodb_table_names" {
  description = "Map of DynamoDB table names for Lambda environment variables"
  type        = map(string)
  default     = {}
}

variable "dynamodb_stream_mappings" {
  description = "Map of DynamoDB stream configurations for Lambda event source mappings"
  type = map(object({
    stream_arn              = string
    batch_size              = number
    batching_window         = number
    max_retries             = number
    filter_pattern          = string
    parallelization_factor  = number
    failure_destination_arn = string
  }))
  default = {}
}

# Additional Configuration for EcoVolt Backend
variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
  default     = ""
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for authentication"
  type        = string
  default     = ""
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
  default     = ""
}

variable "cognito_admin_client_id" {
  description = "Cognito App Client ID for admin portal"
  type        = string
}

variable "iot_endpoint" {
  description = "AWS IoT Core endpoint for device communication"
  type        = string
  default     = ""
}
