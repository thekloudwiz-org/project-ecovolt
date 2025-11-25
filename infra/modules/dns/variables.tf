# DNS Module Variables

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "root_domain" {
  description = "Root domain name (e.g., thekloudwiz.com)"
  type        = string
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for this project (e.g., ecovolt)"
  type        = string
  default     = "ecovolt"
}

variable "use_wildcard_certificate" {
  description = "Whether to use wildcard certificate (less secure) or specific certificates"
  type        = bool
  default     = false
}

variable "additional_domains" {
  description = "Additional domains to include in certificate SANs"
  type        = list(string)
  default     = []
}
