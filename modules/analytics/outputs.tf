# Analytics Module - Outputs

# Kinesis Stream
output "kinesis_stream_name" {
  description = "Kinesis Data Stream name"
  value       = aws_kinesis_stream.telemetry.name
}

output "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = aws_kinesis_stream.telemetry.arn
}

output "kinesis_stream_id" {
  description = "Kinesis Data Stream ID"
  value       = aws_kinesis_stream.telemetry.id
}

output "kinesis_shard_count" {
  description = "Number of shards in Kinesis stream"
  value       = aws_kinesis_stream.telemetry.shard_count
}

# NOTE: Timestream outputs removed due to deprecation
# Telemetry data is now stored in DynamoDB tables (see dynamodb module)
# For time-series analytics, use:
# - S3 Data Lake + Athena for historical analysis
# - DynamoDB tables with TTL for operational data

# S3 Data Lake
output "s3_bucket_name" {
  description = "S3 bucket name for data lake"
  value       = aws_s3_bucket.data_lake.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for data lake"
  value       = aws_s3_bucket.data_lake.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.data_lake.bucket_domain_name
}

# Glue Database
output "glue_database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.data_lake.name
}

output "glue_database_arn" {
  description = "Glue catalog database ARN"
  value       = aws_glue_catalog_database.data_lake.arn
}

output "glue_crawler_name" {
  description = "Glue crawler name (if enabled)"
  value       = var.enable_glue_crawler ? aws_glue_crawler.data_lake[0].name : null
}

output "glue_crawler_arn" {
  description = "Glue crawler ARN (if enabled)"
  value       = var.enable_glue_crawler ? aws_glue_crawler.data_lake[0].arn : null
}

# Lambda Functions
output "lambda_stream_processor_name" {
  description = "Lambda stream processor function name"
  value       = aws_lambda_function.stream_processor.function_name
}

output "lambda_stream_processor_arn" {
  description = "Lambda stream processor function ARN"
  value       = aws_lambda_function.stream_processor.arn
}

output "lambda_transformer_name" {
  description = "Lambda data transformer function name"
  value       = aws_lambda_function.data_transformer.function_name
}

output "lambda_transformer_arn" {
  description = "Lambda data transformer function ARN"
  value       = aws_lambda_function.data_transformer.arn
}

# Kinesis Firehose
output "firehose_name" {
  description = "Kinesis Firehose delivery stream name (if enabled)"
  value       = var.enable_firehose ? aws_kinesis_firehose_delivery_stream.telemetry_to_s3.name : null
}

output "firehose_arn" {
  description = "Kinesis Firehose delivery stream ARN (if enabled)"
  value       = var.enable_firehose ? aws_kinesis_firehose_delivery_stream.telemetry_to_s3.arn : null
}

# Athena
output "athena_workgroup_name" {
  description = "Athena workgroup name (if enabled)"
  value       = var.enable_athena ? aws_athena_workgroup.analytics[0].name : null
}

output "athena_workgroup_arn" {
  description = "Athena workgroup ARN (if enabled)"
  value       = var.enable_athena ? aws_athena_workgroup.analytics[0].arn : null
}

output "athena_results_bucket" {
  description = "S3 bucket for Athena query results (if enabled)"
  value       = var.enable_athena ? aws_s3_bucket.athena_results[0].id : null
}

# IAM Roles
output "lambda_processor_role_arn" {
  description = "IAM role ARN for Lambda stream processor"
  value       = aws_iam_role.lambda_processor.arn
}

output "lambda_transformer_role_arn" {
  description = "IAM role ARN for Lambda data transformer"
  value       = aws_iam_role.lambda_transformer.arn
}

output "firehose_role_arn" {
  description = "IAM role ARN for Kinesis Firehose (if enabled)"
  value       = var.enable_firehose ? aws_iam_role.firehose.arn : null
}

output "glue_crawler_role_arn" {
  description = "IAM role ARN for Glue crawler (if enabled)"
  value       = var.enable_glue_crawler ? aws_iam_role.glue_crawler[0].arn : null
}

# SSM Parameter Store Paths
output "ssm_kinesis_stream_arn_parameter" {
  description = "SSM Parameter name for Kinesis stream ARN"
  value       = aws_ssm_parameter.kinesis_stream_arn.name
}

# Timestream SSM parameter removed - see DynamoDB module for telemetry tables

output "ssm_s3_bucket_parameter" {
  description = "SSM Parameter name for S3 data lake bucket"
  value       = aws_ssm_parameter.s3_bucket.name
}

output "ssm_glue_database_parameter" {
  description = "SSM Parameter name for Glue database"
  value       = aws_ssm_parameter.glue_database.name
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for analytics resources"
  value       = local.ssm_prefix
}

# Kinesis Firehose Outputs
output "firehose_delivery_stream_name" {
  description = "Name of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.telemetry_to_s3.name
}

output "firehose_delivery_stream_arn" {
  description = "ARN of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.telemetry_to_s3.arn
}
