# Compliance Module - Variables

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "config_delivery_frequency" {
  description = "Config snapshot delivery frequency"
  type        = string
  default     = "TwentyFour_Hours"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
