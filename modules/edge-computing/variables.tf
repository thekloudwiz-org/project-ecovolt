# Edge Computing Module - Variables

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iot_core_endpoint" {
  description = "IoT Core endpoint for Greengrass connectivity"
  type        = string
  default     = ""
}

variable "greengrass_core_devices" {
  description = "List of Greengrass core device names"
  type        = list(string)
  default     = []
}

variable "enable_local_logging" {
  description = "Enable local logging on Greengrass devices"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
