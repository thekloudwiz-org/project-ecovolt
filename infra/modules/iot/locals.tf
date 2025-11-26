# IoT Module - Local Variables

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Resource names
  iot_policy_name        = var.iot_policy_name != "" ? var.iot_policy_name : "${local.name_prefix}-iot-policy"
  firmware_bucket_name   = var.firmware_s3_bucket != "" ? var.firmware_s3_bucket : lower("${local.name_prefix}-firmware-${data.aws_caller_identity.current.account_id}")
  device_management_role = "${local.name_prefix}-device-mgmt-role"
  iot_logging_role       = "${local.name_prefix}-iot-logging-role"

  # IoT Thing Types
  bike_thing_type    = "${local.name_prefix}-bike"
  station_thing_type = "${local.name_prefix}-station"
  battery_thing_type = "${local.name_prefix}-battery"

  # IoT Rules
  bike_telemetry_rule = "${local.name_prefix}-bike-telemetry"
  station_energy_rule = "${local.name_prefix}-station-energy"
  station_swap_rule   = "${local.name_prefix}-station-swap"

  # MQTT Topics
  bike_telemetry_topic = "ecovolt/bikes/+/telemetry"
  station_energy_topic = "ecovolt/stations/+/energy"
  station_swap_topic   = "ecovolt/stations/+/swap"

  # SSM Parameter Store prefix
  ssm_prefix = "/ecovolt/${var.environment}/iot"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "iot"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  )
}
