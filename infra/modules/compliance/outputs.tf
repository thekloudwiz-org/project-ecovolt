# Compliance Module - Outputs

output "config_recorder_id" {
  description = "Config recorder ID"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
}

output "config_bucket" {
  description = "Config S3 bucket"
  value       = var.enable_config ? aws_s3_bucket.config[0].id : null
}
