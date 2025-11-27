# Amazon DynamoDB Module
# Stores operational data: EV station info, user profiles, last known status

# EV Stations Table
resource "aws_dynamodb_table" "stations" {
  name             = "${var.project_name}-${var.environment}-stations"
  billing_mode     = var.billing_mode
  hash_key         = "stationId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Provisioned capacity (only used if billing_mode = "PROVISIONED")
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.stations_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.stations_write_capacity : null

  # Attributes
  attribute {
    name = "stationId"
    type = "S"
  }

  attribute {
    name = "location"
    type = "S" # Format: "lat,lon" for geospatial queries
  }

  attribute {
    name = "status"
    type = "S" # active, maintenance, offline
  }

  # GSI for location-based queries
  global_secondary_index {
    name            = "LocationIndex"
    hash_key        = "location"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for status queries
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # TTL (stations don't expire, but keeping for consistency)
  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-stations"
    }
  )
}

# User Profiles Table
resource "aws_dynamodb_table" "user_profiles" {
  name             = "${var.project_name}-${var.environment}-user-profiles"
  billing_mode     = var.billing_mode
  hash_key         = "userId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.users_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.users_write_capacity : null

  # Attributes
  attribute {
    name = "userId"
    type = "S" # Cognito sub (UUID)
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N" # Unix timestamp
  }

  # GSI for email lookups
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for time-based queries
  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "createdAt"
    projection_type = "KEYS_ONLY"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-user-profiles"
    }
  )
}

# Bike Last Known Status Table
resource "aws_dynamodb_table" "bike_status" {
  name             = "${var.project_name}-${var.environment}-bike-status"
  billing_mode     = var.billing_mode
  hash_key         = "bikeId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.bike_status_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.bike_status_write_capacity : null

  # Attributes
  attribute {
    name = "bikeId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "lastUpdated"
    type = "N" # Unix timestamp
  }

  attribute {
    name = "batteryLevel"
    type = "N" # 0-100
  }

  # GSI for user's bikes
  global_secondary_index {
    name            = "UserBikesIndex"
    hash_key        = "userId"
    range_key       = "lastUpdated"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for low battery alerts
  global_secondary_index {
    name            = "BatteryLevelIndex"
    hash_key        = "batteryLevel"
    range_key       = "lastUpdated"
    projection_type = "KEYS_ONLY"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # TTL for old status records (optional)
  ttl {
    attribute_name = "ttl"
    enabled        = var.enable_bike_status_ttl
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bike-status"
    }
  )
}

# Battery Inventory Table (at stations)
resource "aws_dynamodb_table" "battery_inventory" {
  name             = "${var.project_name}-${var.environment}-battery-inventory"
  billing_mode     = var.billing_mode
  hash_key         = "batteryId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.battery_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.battery_write_capacity : null

  # Attributes
  attribute {
    name = "batteryId"
    type = "S"
  }

  attribute {
    name = "stationId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S" # available, charging, swapping, maintenance, retired
  }

  attribute {
    name = "stateOfCharge"
    type = "N" # 0-100
  }

  # GSI for station's batteries
  global_secondary_index {
    name            = "StationBatteriesIndex"
    hash_key        = "stationId"
    range_key       = "status"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for available batteries by charge level
  global_secondary_index {
    name            = "AvailableBatteriesIndex"
    hash_key        = "status"
    range_key       = "stateOfCharge"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-battery-inventory"
    }
  )
}

# Swap Events Table (transaction history)
resource "aws_dynamodb_table" "swap_events" {
  name             = "${var.project_name}-${var.environment}-swap-events"
  billing_mode     = var.billing_mode
  hash_key         = "swapId"
  range_key        = "timestamp"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.swap_events_read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.swap_events_write_capacity : null

  # Attributes
  attribute {
    name = "swapId"
    type = "S" # UUID
  }

  attribute {
    name = "timestamp"
    type = "N" # Unix timestamp
  }

  attribute {
    name = "bikeId"
    type = "S"
  }

  attribute {
    name = "stationId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  # GSI for bike's swap history
  global_secondary_index {
    name            = "BikeSwapsIndex"
    hash_key        = "bikeId"
    range_key       = "timestamp"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for station's swap history
  global_secondary_index {
    name            = "StationSwapsIndex"
    hash_key        = "stationId"
    range_key       = "timestamp"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # GSI for user's swap history
  global_secondary_index {
    name            = "UserSwapsIndex"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # TTL for old swap events (keep for 90 days)
  ttl {
    attribute_name = "ttl"
    enabled        = var.enable_swap_events_ttl
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-swap-events"
    }
  )
}

# Auto-scaling for provisioned capacity (if enabled)
resource "aws_appautoscaling_target" "stations_read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_read_capacity
  min_capacity       = var.stations_read_capacity
  resource_id        = "table/${aws_dynamodb_table.stations.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "stations_read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-stations-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.stations_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.stations_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.stations_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "stations_read_throttle" {
  alarm_name          = "${var.project_name}-${var.environment}-stations-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Stations table read throttle events"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    TableName = aws_dynamodb_table.stations.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "stations_write_throttle" {
  alarm_name          = "${var.project_name}-${var.environment}-stations-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Stations table write throttle events"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    TableName = aws_dynamodb_table.stations.name
  }

  tags = var.tags
}
