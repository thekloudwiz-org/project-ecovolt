# WAF Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_cloudfront_waf" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_api_gateway_waf" {
  description = "Enable WAF for API Gateway"
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "cloudfront_rate_limit" {
  description = "Rate limit for CloudFront (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "api_gateway_rate_limit" {
  description = "Rate limit for API Gateway (requests per 5 minutes per IP)"
  type        = number
  default     = 1000
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

variable "cloudfront_rule_exclusions" {
  description = "List of CloudFront WAF rules to exclude"
  type        = list(string)
  default     = []
}

variable "api_gateway_rule_exclusions" {
  description = "List of API Gateway WAF rules to exclude"
  type        = list(string)
  default     = []
}

variable "blocked_requests_threshold" {
  description = "Threshold for blocked requests alarm"
  type        = number
  default     = 100
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
