# IoT Module - Main Configuration
# Creates IoT Core resources for device connectivity and management

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IoT Thing Type for Bikes
resource "aws_iot_thing_type" "bike" {
  name = local.bike_thing_type

  properties {
    description           = "EcoVolt electric bike with swappable battery"
    searchable_attributes = ["model", "manufacturer", "serialNumber"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.bike_thing_type
      Type = "Bike"
    }
  )
}

# IoT Thing Type for Stations
resource "aws_iot_thing_type" "station" {
  name = local.station_thing_type

  properties {
    description           = "EcoVolt battery swap station with solar panels"
    searchable_attributes = ["location", "capacity", "stationId"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.station_thing_type
      Type = "Station"
    }
  )
}

# IoT Thing Type for Batteries
resource "aws_iot_thing_type" "battery" {
  name = local.battery_thing_type

  properties {
    description           = "EcoVolt swappable battery pack"
    searchable_attributes = ["batteryId", "capacity", "chemistry"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.battery_thing_type
      Type = "Battery"
    }
  )
}

# IoT Policy for device permissions
resource "aws_iot_policy" "device_policy" {
  name = local.iot_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/ecovolt/bikes/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/ecovolt/stations/$${iot:Connection.Thing.ThingName}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/ecovolt/bikes/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/ecovolt/stations/$${iot:Connection.Thing.ThingName}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/ecovolt/bikes/$${iot:Connection.Thing.ThingName}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/ecovolt/stations/$${iot:Connection.Thing.ThingName}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:UpdateThingShadow",
          "iot:GetThingShadow"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:thing/$${iot:Connection.Thing.ThingName}"
      }
    ]
  })
}

# IAM Role for IoT Core Logging
resource "aws_iam_role" "iot_logging" {
  count = var.enable_logging ? 1 : 0

  name = local.iot_logging_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for IoT Core Logging
resource "aws_iam_role_policy" "iot_logging" {
  count = var.enable_logging ? 1 : 0

  name = "${local.name_prefix}-iot-logging-policy"
  role = aws_iam_role.iot_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:AWSIotLogsV2:*"
      }
    ]
  })
}

# Configure IoT Core Logging
resource "aws_iot_logging_options" "main" {
  count = var.enable_logging ? 1 : 0

  default_log_level = "INFO"
  role_arn          = aws_iam_role.iot_logging[0].arn

  depends_on = [aws_iam_role_policy.iot_logging]
}

# Enable IoT Fleet Indexing
resource "aws_iot_indexing_configuration" "main" {
  count = var.enable_fleet_indexing ? 1 : 0

  thing_indexing_configuration {
    thing_indexing_mode              = "REGISTRY_AND_SHADOW"
    thing_connectivity_indexing_mode = "STATUS"

    # Custom fields for device attributes
    # Note: connectivity.connected is automatically indexed when 
    # thing_connectivity_indexing_mode = "STATUS" and should not be defined here
    custom_field {
      name = "attributes.model"
      type = "String"
    }

    custom_field {
      name = "attributes.manufacturer"
      type = "String"
    }

    custom_field {
      name = "attributes.serialNumber"
      type = "String"
    }
  }

  thing_group_indexing_configuration {
    thing_group_indexing_mode = "ON"
  }
}

# S3 Bucket for Firmware Images
resource "aws_s3_bucket" "firmware" {
  bucket = local.firmware_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name    = local.firmware_bucket_name
      Purpose = "Firmware Storage"
    }
  )
}

# S3 Bucket Versioning for Firmware
resource "aws_s3_bucket_versioning" "firmware" {
  bucket = aws_s3_bucket.firmware.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption for Firmware
resource "aws_s3_bucket_server_side_encryption_configuration" "firmware" {
  bucket = aws_s3_bucket.firmware.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for Firmware
resource "aws_s3_bucket_public_access_block" "firmware" {
  bucket = aws_s3_bucket.firmware.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Device Management Operations
resource "aws_iam_role" "device_management" {
  name = local.device_management_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "iot.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.device_management_role
    }
  )
}

# IAM Policy for Device Management
resource "aws_iam_role_policy" "device_management" {
  name = "${local.name_prefix}-device-mgmt-policy"
  role = aws_iam_role.device_management.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:CreateThing",
          "iot:UpdateThing",
          "iot:DeleteThing",
          "iot:DescribeThing",
          "iot:ListThings",
          "iot:CreateThingGroup",
          "iot:UpdateThingGroup",
          "iot:DeleteThingGroup",
          "iot:AddThingToThingGroup",
          "iot:RemoveThingFromThingGroup",
          "iot:ListThingGroups",
          "iot:DescribeThingGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:CreateJob",
          "iot:DescribeJob",
          "iot:CancelJob",
          "iot:ListJobs",
          "iot:UpdateJob"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:SearchIndex",
          "iot:DescribeIndex"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.firmware.arn,
          "${aws_s3_bucket.firmware.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/iot/*"
      }
    ]
  })
}

# IAM Role for IoT Rules
resource "aws_iam_role" "iot_rules" {
  name = "${local.name_prefix}-iot-rules-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for IoT Rules to write to Kinesis
resource "aws_iam_role_policy" "iot_rules_kinesis" {
  name = "${local.name_prefix}-iot-rules-kinesis-policy"
  role = aws_iam_role.iot_rules.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = var.telemetry_kinesis_stream_arn != "" ? var.telemetry_kinesis_stream_arn : "*"
      }
    ]
  })
}

# IoT Rule for Bike Telemetry
resource "aws_iot_topic_rule" "bike_telemetry" {
  name        = replace(local.bike_telemetry_rule, "-", "_")
  description = "Route bike telemetry data to Kinesis stream"
  enabled     = true
  sql         = "SELECT * FROM '${local.bike_telemetry_topic}'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn      = aws_iam_role.iot_rules.arn
    stream_name   = split("/", var.telemetry_kinesis_stream_arn)[1]
    partition_key = "$${topic(3)}"
  }

  tags = merge(
    local.common_tags,
    {
      Name  = local.bike_telemetry_rule
      Topic = local.bike_telemetry_topic
    }
  )

  depends_on = [aws_iam_role.iot_rules]
}

# IoT Rule for Station Energy Data
resource "aws_iot_topic_rule" "station_energy" {
  name        = replace(local.station_energy_rule, "-", "_")
  description = "Route station energy data to Kinesis stream"
  enabled     = true
  sql         = "SELECT * FROM '${local.station_energy_topic}'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn      = aws_iam_role.iot_rules.arn
    stream_name   = split("/", var.telemetry_kinesis_stream_arn)[1]
    partition_key = "$${topic(3)}"
  }

  tags = merge(
    local.common_tags,
    {
      Name  = local.station_energy_rule
      Topic = local.station_energy_topic
    }
  )

  depends_on = [aws_iam_role.iot_rules]
}

# IoT Rule for Battery Swap Events
resource "aws_iot_topic_rule" "station_swap" {
  name        = replace(local.station_swap_rule, "-", "_")
  description = "Route battery swap events to Kinesis stream"
  enabled     = true
  sql         = "SELECT * FROM '${local.station_swap_topic}'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn      = aws_iam_role.iot_rules.arn
    stream_name   = split("/", var.telemetry_kinesis_stream_arn)[1]
    partition_key = "$${topic(3)}"
  }

  tags = merge(
    local.common_tags,
    {
      Name  = local.station_swap_rule
      Topic = local.station_swap_topic
    }
  )

  depends_on = [aws_iam_role.iot_rules]
}
