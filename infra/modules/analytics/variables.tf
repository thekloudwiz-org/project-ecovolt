# Analytics Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Name for Kinesis Data Stream (auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 2

  validation {
    condition     = var.kinesis_shard_count >= 1 && var.kinesis_shard_count <= 200
    error_message = "Kinesis shard count must be between 1 and 200."
  }
}

variable "kinesis_retention_hours" {
  description = "Data retention period in hours for Kinesis stream (24-8760)"
  type        = number
  default     = 24

  validation {
    condition     = var.kinesis_retention_hours >= 24 && var.kinesis_retention_hours <= 8760
    error_message = "Kinesis retention must be between 24 hours (1 day) and 8760 hours (365 days)."
  }
}

variable "timestream_database_name" {
  description = "Name for Timestream database (auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "timestream_memory_retention_hours" {
  description = "Memory store retention in hours for Timestream"
  type        = number
  default     = 24

  validation {
    condition     = var.timestream_memory_retention_hours >= 1 && var.timestream_memory_retention_hours <= 8766
    error_message = "Timestream memory retention must be between 1 and 8766 hours."
  }
}

variable "timestream_magnetic_retention_days" {
  description = "Magnetic store retention in days for Timestream"
  type        = number
  default     = 90

  validation {
    condition     = var.timestream_magnetic_retention_days >= 1 && var.timestream_magnetic_retention_days <= 73000
    error_message = "Timestream magnetic retention must be between 1 and 73000 days."
  }
}

variable "s3_bucket_name" {
  description = "S3 bucket name for data lake (auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "s3_lifecycle_glacier_days" {
  description = "Number of days before transitioning S3 objects to Glacier"
  type        = number
  default     = 90

  validation {
    condition     = var.s3_lifecycle_glacier_days >= 30
    error_message = "S3 Glacier transition must be at least 30 days."
  }
}

variable "s3_lifecycle_deep_archive_days" {
  description = "Number of days before transitioning S3 objects to Glacier Deep Archive"
  type        = number
  default     = 180

  validation {
    condition     = var.s3_lifecycle_deep_archive_days >= 90
    error_message = "S3 Deep Archive transition must be at least 90 days."
  }
}

variable "glue_database_name" {
  description = "Name for Glue database (auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "enable_firehose" {
  description = "Enable Kinesis Data Firehose for S3 archival"
  type        = bool
  default     = true
}

variable "enable_athena" {
  description = "Enable Athena workgroup for querying data lake"
  type        = bool
  default     = true
}

variable "enable_glue_crawler" {
  description = "Enable Glue crawler for data catalog"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Kinesis Firehose Variables
variable "firehose_buffer_size" {
  description = "Firehose buffer size in MB (1-128)"
  type        = number
  default     = 5
}

variable "firehose_buffer_interval" {
  description = "Firehose buffer interval in seconds (60-900)"
  type        = number
  default     = 300
}

variable "enable_firehose_transformation" {
  description = "Enable Lambda transformation for Firehose data"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

# DynamoDB Table Names (for stream processor Lambda)
variable "bike_telemetry_table_name" {
  description = "Name of the DynamoDB bike telemetry table"
  type        = string
  default     = ""
}

variable "station_energy_table_name" {
  description = "Name of the DynamoDB station energy table"
  type        = string
  default     = ""
}

variable "swap_events_table_name" {
  description = "Name of the DynamoDB swap events table"
  type        = string
  default     = ""
}
