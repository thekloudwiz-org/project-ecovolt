# WAF Module Outputs

# CloudFront Web ACL
output "cloudfront_web_acl_id" {
  description = "ID of the CloudFront Web ACL"
  value       = var.enable_cloudfront_waf ? aws_wafv2_web_acl.cloudfront[0].id : null
}

output "cloudfront_web_acl_arn" {
  description = "ARN of the CloudFront Web ACL"
  value       = var.enable_cloudfront_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null
}

# API Gateway Web ACL
output "api_gateway_web_acl_id" {
  description = "ID of the API Gateway Web ACL"
  value       = var.enable_api_gateway_waf ? aws_wafv2_web_acl.api_gateway[0].id : null
}

output "api_gateway_web_acl_arn" {
  description = "ARN of the API Gateway Web ACL"
  value       = var.enable_api_gateway_waf ? aws_wafv2_web_acl.api_gateway[0].arn : null
}

# Log Groups
output "cloudfront_waf_log_group_name" {
  description = "Name of the CloudFront WAF log group"
  value       = var.enable_cloudfront_waf && var.enable_waf_logging ? aws_cloudwatch_log_group.cloudfront_waf[0].name : null
}

output "api_gateway_waf_log_group_name" {
  description = "Name of the API Gateway WAF log group"
  value       = var.enable_api_gateway_waf && var.enable_waf_logging ? aws_cloudwatch_log_group.api_gateway_waf[0].name : null
}
