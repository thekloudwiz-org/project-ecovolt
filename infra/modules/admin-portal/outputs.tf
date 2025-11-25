# Admin Portal Module Outputs

output "s3_bucket_name" {
  description = "S3 bucket name for admin portal"
  value       = aws_s3_bucket.admin_portal.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for admin portal"
  value       = aws_s3_bucket.admin_portal.arn
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.admin_portal.bucket_regional_domain_name
}

output "backup_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.admin_portal_backups.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.admin_portal.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.admin_portal.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.admin_portal.domain_name
}

output "admin_portal_url" {
  description = "Admin portal URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.admin_portal.domain_name}"
}
