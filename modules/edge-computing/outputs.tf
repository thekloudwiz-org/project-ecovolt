# Edge Computing Module - Outputs

output "greengrass_core_role_arn" {
  description = "Greengrass core device IAM role ARN"
  value       = aws_iam_role.greengrass_core.arn
}

output "greengrass_components_bucket" {
  description = "S3 bucket for Greengrass components"
  value       = aws_s3_bucket.greengrass_components.id
}
