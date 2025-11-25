# IoT Module - SSM Parameter Store
# Store IoT resource identifiers in SSM for cross-module reference

# IoT Endpoint
resource "aws_ssm_parameter" "iot_endpoint" {
  name        = "${local.ssm_prefix}/endpoint"
  description = "IoT Core MQTT endpoint address"
  type        = "String"
  value       = data.aws_iot_endpoint.main.endpoint_address

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-iot-endpoint"
    }
  )
}

# IoT Policy ARN
resource "aws_ssm_parameter" "iot_policy_arn" {
  name        = "${local.ssm_prefix}/policy-arn"
  description = "IoT device policy ARN"
  type        = "String"
  value       = aws_iot_policy.device_policy.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-iot-policy-arn"
    }
  )
}

# Bike Thing Type ARN
resource "aws_ssm_parameter" "bike_thing_type_arn" {
  name        = "${local.ssm_prefix}/thing-types/bike-arn"
  description = "Bike thing type ARN"
  type        = "String"
  value       = aws_iot_thing_type.bike.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-bike-thing-type-arn"
    }
  )
}

# Station Thing Type ARN
resource "aws_ssm_parameter" "station_thing_type_arn" {
  name        = "${local.ssm_prefix}/thing-types/station-arn"
  description = "Station thing type ARN"
  type        = "String"
  value       = aws_iot_thing_type.station.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-station-thing-type-arn"
    }
  )
}

# Battery Thing Type ARN
resource "aws_ssm_parameter" "battery_thing_type_arn" {
  name        = "${local.ssm_prefix}/thing-types/battery-arn"
  description = "Battery thing type ARN"
  type        = "String"
  value       = aws_iot_thing_type.battery.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-battery-thing-type-arn"
    }
  )
}

# Firmware S3 Bucket
resource "aws_ssm_parameter" "firmware_bucket" {
  name        = "${local.ssm_prefix}/firmware-bucket"
  description = "S3 bucket name for firmware images"
  type        = "String"
  value       = aws_s3_bucket.firmware.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-firmware-bucket"
    }
  )
}

# Device Management Role ARN
resource "aws_ssm_parameter" "device_management_role_arn" {
  name        = "${local.ssm_prefix}/device-mgmt-role-arn"
  description = "IAM role ARN for device management operations"
  type        = "String"
  value       = aws_iam_role.device_management.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-device-mgmt-role-arn"
    }
  )
}

# MQTT Topics
resource "aws_ssm_parameter" "mqtt_topics" {
  name        = "${local.ssm_prefix}/mqtt-topics"
  description = "MQTT topic patterns (JSON)"
  type        = "String"
  value = jsonencode({
    bike_telemetry = local.bike_telemetry_topic
    station_energy = local.station_energy_topic
    station_swap   = local.station_swap_topic
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mqtt-topics"
    }
  )
}
