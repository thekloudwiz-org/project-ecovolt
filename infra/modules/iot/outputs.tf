# IoT Module - Outputs

# IoT Core Endpoint
data "aws_iot_endpoint" "main" {
  endpoint_type = "iot:Data-ATS"
}

output "iot_endpoint" {
  description = "IoT Core MQTT endpoint"
  value       = data.aws_iot_endpoint.main.endpoint_address
}

output "iot_endpoint_type" {
  description = "IoT Core endpoint type"
  value       = data.aws_iot_endpoint.main.endpoint_type
}

# Thing Types
output "bike_thing_type_name" {
  description = "Bike thing type name"
  value       = aws_iot_thing_type.bike.name
}

output "bike_thing_type_arn" {
  description = "Bike thing type ARN"
  value       = aws_iot_thing_type.bike.arn
}

output "station_thing_type_name" {
  description = "Station thing type name"
  value       = aws_iot_thing_type.station.name
}

output "station_thing_type_arn" {
  description = "Station thing type ARN"
  value       = aws_iot_thing_type.station.arn
}

output "battery_thing_type_name" {
  description = "Battery thing type name"
  value       = aws_iot_thing_type.battery.name
}

output "battery_thing_type_arn" {
  description = "Battery thing type ARN"
  value       = aws_iot_thing_type.battery.arn
}

# IoT Policy
output "iot_policy_name" {
  description = "IoT policy name"
  value       = aws_iot_policy.device_policy.name
}

output "iot_policy_arn" {
  description = "IoT policy ARN"
  value       = aws_iot_policy.device_policy.arn
}

# IoT Rules
output "iot_rule_arns" {
  description = "Map of IoT rule names to ARNs"
  value = {
    bike_telemetry = aws_iot_topic_rule.bike_telemetry.arn
    station_energy = aws_iot_topic_rule.station_energy.arn
    station_swap   = aws_iot_topic_rule.station_swap.arn
  }
}

output "iot_rule_names" {
  description = "Map of IoT rule names"
  value = {
    bike_telemetry = aws_iot_topic_rule.bike_telemetry.name
    station_energy = aws_iot_topic_rule.station_energy.name
    station_swap   = aws_iot_topic_rule.station_swap.name
  }
}

# MQTT Topics
output "mqtt_topics" {
  description = "MQTT topic patterns for device communication"
  value = {
    bike_telemetry = local.bike_telemetry_topic
    station_energy = local.station_energy_topic
    station_swap   = local.station_swap_topic
  }
}

# Fleet Indexing
output "fleet_indexing_enabled" {
  description = "Whether IoT Fleet Indexing is enabled"
  value       = var.enable_fleet_indexing
}

output "fleet_index_name" {
  description = "Fleet index name for device queries"
  value       = var.enable_fleet_indexing ? "AWS_Things" : null
}

# Firmware Storage
output "firmware_bucket_name" {
  description = "S3 bucket name for firmware images"
  value       = aws_s3_bucket.firmware.id
}

output "firmware_bucket_arn" {
  description = "S3 bucket ARN for firmware images"
  value       = aws_s3_bucket.firmware.arn
}

# IAM Roles
output "device_management_role_arn" {
  description = "IAM role ARN for device management operations"
  value       = aws_iam_role.device_management.arn
}

output "device_management_role_name" {
  description = "IAM role name for device management operations"
  value       = aws_iam_role.device_management.name
}

output "iot_rules_role_arn" {
  description = "IAM role ARN for IoT Rules"
  value       = aws_iam_role.iot_rules.arn
}

output "iot_rules_role_name" {
  description = "IAM role name for IoT Rules"
  value       = aws_iam_role.iot_rules.name
}

output "iot_logging_role_arn" {
  description = "IAM role ARN for IoT Core logging (if enabled)"
  value       = var.enable_logging ? aws_iam_role.iot_logging[0].arn : null
}

# Logging
output "iot_logging_enabled" {
  description = "Whether IoT Core logging is enabled"
  value       = var.enable_logging
}

# SSM Parameter Store Paths
output "ssm_iot_endpoint_parameter" {
  description = "SSM Parameter name for IoT endpoint"
  value       = "${local.ssm_prefix}/endpoint"
}

output "ssm_iot_policy_arn_parameter" {
  description = "SSM Parameter name for IoT policy ARN"
  value       = "${local.ssm_prefix}/policy-arn"
}

output "ssm_firmware_bucket_parameter" {
  description = "SSM Parameter name for firmware bucket"
  value       = "${local.ssm_prefix}/firmware-bucket"
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for IoT resources"
  value       = local.ssm_prefix
}
