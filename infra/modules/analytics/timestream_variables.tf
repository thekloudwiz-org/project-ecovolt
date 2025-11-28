# Timestream for InfluxDB Variables

variable "influxdb_instance_type" {
  description = "InfluxDB instance type"
  type        = string
  default     = "db.influx.medium"

  validation {
    condition     = can(regex("^db\\.influx\\.(medium|large|xlarge|2xlarge|4xlarge|8xlarge|12xlarge|16xlarge)$", var.influxdb_instance_type))
    error_message = "InfluxDB instance type must be a valid db.influx.* type."
  }
}

variable "influxdb_storage_gb" {
  description = "Allocated storage for InfluxDB in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.influxdb_storage_gb >= 20 && var.influxdb_storage_gb <= 16384
    error_message = "InfluxDB storage must be between 20 GB and 16384 GB."
  }
}

variable "influxdb_deployment_type" {
  description = "InfluxDB deployment type (SINGLE_AZ or WITH_MULTIAZ_STANDBY)"
  type        = string
  default     = "SINGLE_AZ"

  validation {
    condition     = contains(["SINGLE_AZ", "WITH_MULTIAZ_STANDBY"], var.influxdb_deployment_type)
    error_message = "Deployment type must be SINGLE_AZ or WITH_MULTIAZ_STANDBY."
  }
}


