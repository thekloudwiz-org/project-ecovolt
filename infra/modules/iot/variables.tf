# IoT Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "iot_policy_name" {
  description = "Name for IoT policy"
  type        = string
  default     = ""
}

variable "telemetry_kinesis_stream_arn" {
  description = "ARN of Kinesis stream for telemetry data"
  type        = string
  default     = ""
}

variable "enable_logging" {
  description = "Enable IoT Core logging"
  type        = bool
  default     = true
}

variable "enable_fleet_indexing" {
  description = "Enable IoT Fleet Indexing for device search and query"
  type        = bool
  default     = true
}

variable "firmware_s3_bucket" {
  description = "S3 bucket name for firmware images (if not provided, will be auto-generated)"
  type        = string
  default     = ""
}

variable "enable_device_defender" {
  description = "Enable IoT Device Defender for security auditing"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encrypting Kinesis stream data"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
