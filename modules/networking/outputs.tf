# Networking Module - Outputs

output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "List of data subnet IDs"
  value       = aws_subnet.data[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "data_subnet_cidrs" {
  description = "List of data subnet CIDR blocks"
  value       = aws_subnet.data[*].cidr_block
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT gateways"
  value       = aws_eip.nat[*].public_ip
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "data_route_table_ids" {
  description = "List of data route table IDs"
  value       = aws_route_table.data[*].id
}

output "vpn_gateway_id" {
  description = "VPN Gateway ID (if enabled)"
  value       = var.enable_vpn_gateway ? aws_vpn_gateway.main[0].id : null
}

output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.main.id
}

output "flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

# SSM Parameter Store Paths
output "ssm_vpc_id_parameter" {
  description = "SSM Parameter name for VPC ID"
  value       = aws_ssm_parameter.vpc_id.name
}

output "ssm_public_subnet_ids_parameter" {
  description = "SSM Parameter name for public subnet IDs"
  value       = aws_ssm_parameter.public_subnet_ids.name
}

output "ssm_private_subnet_ids_parameter" {
  description = "SSM Parameter name for private subnet IDs"
  value       = aws_ssm_parameter.private_subnet_ids.name
}

output "ssm_data_subnet_ids_parameter" {
  description = "SSM Parameter name for data subnet IDs"
  value       = aws_ssm_parameter.data_subnet_ids.name
}

output "ssm_nat_gateway_ids_parameter" {
  description = "SSM Parameter name for NAT Gateway IDs (if enabled)"
  value       = var.enable_nat_gateway ? aws_ssm_parameter.nat_gateway_ids[0].name : null
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for networking resources"
  value       = local.ssm_prefix
}

# VPC Endpoint Outputs
output "secretsmanager_endpoint_id" {
  description = "Secrets Manager VPC endpoint ID"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "s3_endpoint_id" {
  description = "S3 VPC endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB VPC endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "cognito_idp_endpoint_id" {
  description = "Cognito Identity Provider VPC endpoint ID"
  value       = aws_vpc_endpoint.cognito_idp.id
}
