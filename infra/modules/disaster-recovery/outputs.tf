# Disaster Recovery Module - Outputs

output "s3_replication_role_arn" {
  description = "S3 replication IAM role ARN"
  value       = var.enable_s3_replication ? aws_iam_role.s3_replication[0].arn : null
}
