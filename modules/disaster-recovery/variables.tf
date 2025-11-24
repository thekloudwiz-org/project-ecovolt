# Disaster Recovery Module - Variables

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
}

variable "enable_s3_replication" {
  description = "Enable S3 cross-region replication"
  type        = bool
  default     = true
}

variable "critical_s3_buckets" {
  description = "List of critical S3 bucket names for replication"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
