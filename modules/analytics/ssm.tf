# Analytics Module - SSM Parameter Store
# Store resource identifiers in SSM for cross-module reference

# Kinesis Stream ARN
resource "aws_ssm_parameter" "kinesis_stream_arn" {
  name        = "${local.ssm_prefix}/kinesis-stream-arn"
  description = "Kinesis Data Stream ARN for telemetry ingestion"
  type        = "String"
  value       = aws_kinesis_stream.telemetry.arn

  tags = local.common_tags
}

# Kinesis Stream Name
resource "aws_ssm_parameter" "kinesis_stream_name" {
  name        = "${local.ssm_prefix}/kinesis-stream-name"
  description = "Kinesis Data Stream name for telemetry ingestion"
  type        = "String"
  value       = aws_kinesis_stream.telemetry.name

  tags = local.common_tags
}

# NOTE: Timestream SSM parameters removed due to deprecation
# Telemetry data is now stored in DynamoDB tables (see dynamodb module)
# Reference DynamoDB table names from the dynamodb module outputs

# S3 Data Lake Bucket
resource "aws_ssm_parameter" "s3_bucket" {
  name        = "${local.ssm_prefix}/s3-bucket"
  description = "S3 bucket name for data lake"
  type        = "String"
  value       = aws_s3_bucket.data_lake.id

  tags = local.common_tags
}

# Glue Database Name
resource "aws_ssm_parameter" "glue_database" {
  name        = "${local.ssm_prefix}/glue-database"
  description = "Glue catalog database name for data lake"
  type        = "String"
  value       = aws_glue_catalog_database.data_lake.name

  tags = local.common_tags
}

# Lambda Stream Processor ARN
resource "aws_ssm_parameter" "lambda_processor_arn" {
  name        = "${local.ssm_prefix}/lambda-processor-arn"
  description = "Lambda stream processor function ARN"
  type        = "String"
  value       = aws_lambda_function.stream_processor.arn

  tags = local.common_tags
}

# Lambda Transformer ARN
resource "aws_ssm_parameter" "lambda_transformer_arn" {
  name        = "${local.ssm_prefix}/lambda-transformer-arn"
  description = "Lambda data transformer function ARN"
  type        = "String"
  value       = aws_lambda_function.data_transformer.arn

  tags = local.common_tags
}

# Athena Workgroup (if enabled)
resource "aws_ssm_parameter" "athena_workgroup" {
  count       = var.enable_athena ? 1 : 0
  name        = "${local.ssm_prefix}/athena-workgroup"
  description = "Athena workgroup name for analytics queries"
  type        = "String"
  value       = aws_athena_workgroup.analytics[0].name

  tags = local.common_tags
}
