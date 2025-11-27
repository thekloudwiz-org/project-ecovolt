# DynamoDB Module Outputs

# Stations Table
output "stations_table_name" {
  description = "Name of the stations table"
  value       = aws_dynamodb_table.stations.name
}

output "stations_table_arn" {
  description = "ARN of the stations table"
  value       = aws_dynamodb_table.stations.arn
}

output "stations_table_stream_arn" {
  description = "ARN of the stations table stream"
  value       = aws_dynamodb_table.stations.stream_arn
}

# User Profiles Table
output "user_profiles_table_name" {
  description = "Name of the user profiles table"
  value       = aws_dynamodb_table.user_profiles.name
}

output "user_profiles_table_arn" {
  description = "ARN of the user profiles table"
  value       = aws_dynamodb_table.user_profiles.arn
}

output "user_profiles_table_stream_arn" {
  description = "ARN of the user profiles table stream"
  value       = aws_dynamodb_table.user_profiles.stream_arn
}

# bike Status Table
output "bike_status_table_name" {
  description = "Name of the bike status table"
  value       = aws_dynamodb_table.bike_status.name
}

output "bike_status_table_arn" {
  description = "ARN of the bike status table"
  value       = aws_dynamodb_table.bike_status.arn
}

output "bike_status_table_stream_arn" {
  description = "ARN of the bike status table stream"
  value       = aws_dynamodb_table.bike_status.stream_arn
}

# Battery Inventory Table
output "battery_inventory_table_name" {
  description = "Name of the battery inventory table"
  value       = aws_dynamodb_table.battery_inventory.name
}

output "battery_inventory_table_arn" {
  description = "ARN of the battery inventory table"
  value       = aws_dynamodb_table.battery_inventory.arn
}

output "battery_inventory_table_stream_arn" {
  description = "ARN of the battery inventory table stream"
  value       = aws_dynamodb_table.battery_inventory.stream_arn
}

# Swap Events Table
output "swap_events_table_name" {
  description = "Name of the swap events table"
  value       = aws_dynamodb_table.swap_events.name
}

output "swap_events_table_arn" {
  description = "ARN of the swap events table"
  value       = aws_dynamodb_table.swap_events.arn
}

output "swap_events_table_stream_arn" {
  description = "ARN of the swap events table stream"
  value       = aws_dynamodb_table.swap_events.stream_arn
}

# All table names (for Lambda environment variables)
output "all_table_names" {
  description = "Map of all table names"
  value = {
    stations          = aws_dynamodb_table.stations.name
    user_profiles     = aws_dynamodb_table.user_profiles.name
    bike_status    = aws_dynamodb_table.bike_status.name
    battery_inventory = aws_dynamodb_table.battery_inventory.name
    swap_events       = aws_dynamodb_table.swap_events.name
  }
}

# All table ARNs (for IAM policies)
output "all_table_arns" {
  description = "List of all table ARNs"
  value = [
    aws_dynamodb_table.stations.arn,
    aws_dynamodb_table.user_profiles.arn,
    aws_dynamodb_table.bike_status.arn,
    aws_dynamodb_table.battery_inventory.arn,
    aws_dynamodb_table.swap_events.arn
  ]
}

# All table stream ARNs (for Lambda triggers)
output "all_table_stream_arns" {
  description = "List of all table stream ARNs"
  value = [
    aws_dynamodb_table.stations.stream_arn,
    aws_dynamodb_table.user_profiles.stream_arn,
    aws_dynamodb_table.bike_status.stream_arn,
    aws_dynamodb_table.battery_inventory.stream_arn,
    aws_dynamodb_table.swap_events.stream_arn
  ]
}
