# Timestream for InfluxDB - Historical Time-Series Data Storage
# Stores voltage, current, temperature, power output, energy generation

resource "aws_timestreaminfluxdb_db_instance" "telemetry" {
  name                   = "${var.project_name}-${var.environment}-telemetry-influxdb"
  username               = "admin"
  password               = random_password.influxdb_password.result
  db_instance_type       = var.influxdb_instance_type
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.influxdb.id]
  allocated_storage      = var.influxdb_storage_gb

  # InfluxDB 2.x configuration
  db_storage_type = "InfluxIOIncludedT1"

  # Organization and bucket (database equivalent)
  organization = var.project_name
  bucket       = "${var.environment}-telemetry"

  # Publicly accessible (set to false for production)
  publicly_accessible = false

  # Deployment type
  deployment_type = var.influxdb_deployment_type

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-telemetry-influxdb"
      Purpose     = "TimeSeriesStorage"
      DataType    = "HistoricalTelemetry"
      Environment = var.environment
    }
  )
}

# Random password for InfluxDB admin user
# Note: InfluxDB password must match ^[a-zA-Z0-9]+$ (alphanumeric only)
resource "random_password" "influxdb_password" {
  length  = 32
  special = false # No special characters allowed
  upper   = true
  lower   = true
  numeric = true

  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
      lower,
      numeric
    ]
  }
}

# Store InfluxDB credentials in Secrets Manager
resource "aws_secretsmanager_secret" "influxdb_credentials" {
  name        = "${var.project_name}-${var.environment}-influxdb-credentials"
  description = "InfluxDB admin credentials for ${var.environment}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-influxdb-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "influxdb_credentials" {
  secret_id = aws_secretsmanager_secret.influxdb_credentials.id
  secret_string = jsonencode({
    username     = "admin"
    password     = random_password.influxdb_password.result
    endpoint     = aws_timestreaminfluxdb_db_instance.telemetry.endpoint
    organization = var.project_name
    bucket       = "${var.environment}-telemetry"
  })
}

# Security Group for Stream Processor Lambda
resource "aws_security_group" "stream_processor" {
  name        = "${var.project_name}-${var.environment}-stream-processor-sg"
  description = "Security group for stream processor Lambda function"
  vpc_id      = var.vpc_id

  # Allow all outbound (for InfluxDB, VPC endpoints)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-stream-processor-sg"
    }
  )
}

# Security Group for InfluxDB
resource "aws_security_group" "influxdb" {
  name        = "${var.project_name}-${var.environment}-influxdb-sg"
  description = "Security group for Timestream InfluxDB instance"
  vpc_id      = var.vpc_id

  # Allow inbound from private subnets (where Lambda runs)
  ingress {
    description = "InfluxDB from private subnets"
    from_port   = 8086
    to_port     = 8086
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Allow outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-influxdb-sg"
    }
  )
}

# SSM Parameters for InfluxDB configuration
resource "aws_ssm_parameter" "influxdb_endpoint" {
  name        = "/${var.project_name}/${var.environment}/influxdb/endpoint"
  description = "InfluxDB endpoint URL"
  type        = "String"
  value       = aws_timestreaminfluxdb_db_instance.telemetry.endpoint

  tags = var.tags
}

resource "aws_ssm_parameter" "influxdb_secret_arn" {
  name        = "/${var.project_name}/${var.environment}/influxdb/secret-arn"
  description = "ARN of InfluxDB credentials secret"
  type        = "String"
  value       = aws_secretsmanager_secret.influxdb_credentials.arn

  tags = var.tags
}

resource "aws_ssm_parameter" "influxdb_organization" {
  name        = "/${var.project_name}/${var.environment}/influxdb/organization"
  description = "InfluxDB organization name"
  type        = "String"
  value       = var.project_name

  tags = var.tags
}

resource "aws_ssm_parameter" "influxdb_bucket" {
  name        = "/${var.project_name}/${var.environment}/influxdb/bucket"
  description = "InfluxDB bucket (database) name"
  type        = "String"
  value       = "${var.environment}-telemetry"

  tags = var.tags
}
