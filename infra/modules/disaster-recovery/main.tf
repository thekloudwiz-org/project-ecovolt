# Disaster Recovery Module - Cross-Region Replication

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Module      = "disaster-recovery"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# IAM Role for S3 Replication
resource "aws_iam_role" "s3_replication" {
  count = var.enable_s3_replication ? 1 : 0
  name  = "${local.name_prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "s3_replication" {
  count = var.enable_s3_replication ? 1 : 0
  name  = "${local.name_prefix}-s3-replication-policy"
  role  = aws_iam_role.s3_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "*"
      }
    ]
  })
}

# Note: Actual S3 replication configuration and RDS read replicas
# are typically configured in their respective modules with DR region parameters
# This module provides the foundational IAM roles and policies
