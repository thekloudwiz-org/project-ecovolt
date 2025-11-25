# Analytics Module - Local Values

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Kinesis Stream
  kinesis_stream_name = var.kinesis_stream_name != "" ? var.kinesis_stream_name : "${local.name_prefix}-telemetry-stream"

  # Timestream
  timestream_database_name = var.timestream_database_name != "" ? var.timestream_database_name : "${local.name_prefix}-telemetry-db"
  timestream_table_bike    = "${local.name_prefix}-bike-telemetry"
  timestream_table_station = "${local.name_prefix}-station-energy"
  timestream_table_swap    = "${local.name_prefix}-swap-events"

  # S3 Data Lake
  s3_bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : "${local.name_prefix}-data-lake-${data.aws_caller_identity.current.account_id}"

  # Glue
  glue_database_name = var.glue_database_name != "" ? var.glue_database_name : "${local.name_prefix}_data_lake"
  glue_crawler_name  = "${local.name_prefix}-data-lake-crawler"

  # Lambda Functions
  lambda_stream_processor_name = "${local.name_prefix}-stream-processor"
  lambda_transformer_name      = "${local.name_prefix}-data-transformer"

  # Kinesis Firehose
  firehose_name = "${local.name_prefix}-telemetry-firehose"

  # Athena
  athena_workgroup_name = "${local.name_prefix}-analytics-workgroup"
  athena_output_bucket  = "${local.name_prefix}-athena-results-${data.aws_caller_identity.current.account_id}"

  # IAM Roles
  lambda_processor_role_name   = "${local.name_prefix}-lambda-processor-role"
  lambda_transformer_role_name = "${local.name_prefix}-lambda-transformer-role"
  firehose_role_name           = "${local.name_prefix}-firehose-role"
  glue_crawler_role_name       = "${local.name_prefix}-glue-crawler-role"

  # SSM Parameters
  ssm_prefix = "/${var.project_name}/${var.environment}/analytics"

  # Common Tags
  common_tags = merge(
    var.tags,
    {
      Module      = "analytics"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  )
}
