# SSM Parameter Store - Networking Module
# Stores networking resource IDs for reference by other modules

# VPC ID
resource "aws_ssm_parameter" "vpc_id" {
  name        = "${local.ssm_prefix}/vpc_id"
  description = "VPC ID for ${var.environment} environment"
  type        = "String"
  value       = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-vpc-id"
    }
  )
}

# VPC CIDR
resource "aws_ssm_parameter" "vpc_cidr" {
  name        = "${local.ssm_prefix}/vpc_cidr"
  description = "VPC CIDR block for ${var.environment} environment"
  type        = "String"
  value       = aws_vpc.main.cidr_block

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-vpc-cidr"
    }
  )
}

# Public Subnet IDs (comma-separated)
resource "aws_ssm_parameter" "public_subnet_ids" {
  name        = "${local.ssm_prefix}/public_subnet_ids"
  description = "Public subnet IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_subnet.public[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-public-subnet-ids"
    }
  )
}

# Private Subnet IDs (comma-separated)
resource "aws_ssm_parameter" "private_subnet_ids" {
  name        = "${local.ssm_prefix}/private_subnet_ids"
  description = "Private subnet IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_subnet.private[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-private-subnet-ids"
    }
  )
}

# Data Subnet IDs (comma-separated)
resource "aws_ssm_parameter" "data_subnet_ids" {
  name        = "${local.ssm_prefix}/data_subnet_ids"
  description = "Data subnet IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_subnet.data[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-data-subnet-ids"
    }
  )
}

# Individual Public Subnet IDs (one parameter per subnet)
resource "aws_ssm_parameter" "public_subnet_id" {
  count = length(var.availability_zones)

  name        = "${local.ssm_prefix}/public_subnet_id_${substr(var.availability_zones[count.index], -2, 2)}"
  description = "Public subnet ID in ${var.availability_zones[count.index]}"
  type        = "String"
  value       = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-public-subnet-${substr(var.availability_zones[count.index], -2, 2)}"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# Individual Private Subnet IDs (one parameter per subnet)
resource "aws_ssm_parameter" "private_subnet_id" {
  count = length(var.availability_zones)

  name        = "${local.ssm_prefix}/private_subnet_id_${substr(var.availability_zones[count.index], -2, 2)}"
  description = "Private subnet ID in ${var.availability_zones[count.index]}"
  type        = "String"
  value       = aws_subnet.private[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-private-subnet-${substr(var.availability_zones[count.index], -2, 2)}"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# Individual Data Subnet IDs (one parameter per subnet)
resource "aws_ssm_parameter" "data_subnet_id" {
  count = length(var.availability_zones)

  name        = "${local.ssm_prefix}/data_subnet_id_${substr(var.availability_zones[count.index], -2, 2)}"
  description = "Data subnet ID in ${var.availability_zones[count.index]}"
  type        = "String"
  value       = aws_subnet.data[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-data-subnet-${substr(var.availability_zones[count.index], -2, 2)}"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# NAT Gateway IDs (comma-separated)
resource "aws_ssm_parameter" "nat_gateway_ids" {
  count = var.enable_nat_gateway ? 1 : 0

  name        = "${local.ssm_prefix}/nat_gateway_ids"
  description = "NAT Gateway IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_nat_gateway.main[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-nat-gateway-ids"
    }
  )
}

# Individual NAT Gateway IDs (one parameter per NAT Gateway)
resource "aws_ssm_parameter" "nat_gateway_id" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  name        = "${local.ssm_prefix}/nat_gateway_id_${substr(var.availability_zones[count.index], -2, 2)}"
  description = "NAT Gateway ID in ${var.availability_zones[count.index]}"
  type        = "String"
  value       = aws_nat_gateway.main[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-nat-gateway-${substr(var.availability_zones[count.index], -2, 2)}"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# NAT Gateway Elastic IPs (comma-separated)
resource "aws_ssm_parameter" "nat_gateway_ips" {
  count = var.enable_nat_gateway ? 1 : 0

  name        = "${local.ssm_prefix}/nat_gateway_ips"
  description = "NAT Gateway Elastic IPs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_eip.nat[*].public_ip)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-nat-gateway-ips"
    }
  )
}

# Internet Gateway ID
resource "aws_ssm_parameter" "internet_gateway_id" {
  name        = "${local.ssm_prefix}/internet_gateway_id"
  description = "Internet Gateway ID for ${var.environment} environment"
  type        = "String"
  value       = aws_internet_gateway.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-igw-id"
    }
  )
}

# Public Route Table ID
resource "aws_ssm_parameter" "public_route_table_id" {
  name        = "${local.ssm_prefix}/public_route_table_id"
  description = "Public route table ID for ${var.environment} environment"
  type        = "String"
  value       = aws_route_table.public.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-public-rt-id"
    }
  )
}

# Private Route Table IDs (comma-separated)
resource "aws_ssm_parameter" "private_route_table_ids" {
  name        = "${local.ssm_prefix}/private_route_table_ids"
  description = "Private route table IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_route_table.private[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-private-rt-ids"
    }
  )
}

# Data Route Table IDs (comma-separated)
resource "aws_ssm_parameter" "data_route_table_ids" {
  name        = "${local.ssm_prefix}/data_route_table_ids"
  description = "Data route table IDs for ${var.environment} environment"
  type        = "StringList"
  value       = join(",", aws_route_table.data[*].id)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-data-rt-ids"
    }
  )
}

# VPC Flow Log ID
resource "aws_ssm_parameter" "flow_log_id" {
  name        = "${local.ssm_prefix}/flow_log_id"
  description = "VPC Flow Log ID for ${var.environment} environment"
  type        = "String"
  value       = aws_flow_log.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-flow-log-id"
    }
  )
}

# VPC Flow Log CloudWatch Log Group Name
resource "aws_ssm_parameter" "flow_log_group_name" {
  name        = "${local.ssm_prefix}/flow_log_group_name"
  description = "VPC Flow Log CloudWatch Log Group name for ${var.environment} environment"
  type        = "String"
  value       = aws_cloudwatch_log_group.flow_logs.name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-flow-log-group-name"
    }
  )
}

# VPN Gateway ID (if enabled)
resource "aws_ssm_parameter" "vpn_gateway_id" {
  count = var.enable_vpn_gateway ? 1 : 0

  name        = "${local.ssm_prefix}/vpn_gateway_id"
  description = "VPN Gateway ID for ${var.environment} environment"
  type        = "String"
  value       = aws_vpn_gateway.main[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-vpn-gateway-id"
    }
  )
}

# Availability Zones (comma-separated)
resource "aws_ssm_parameter" "availability_zones" {
  name        = "${local.ssm_prefix}/availability_zones"
  description = "Availability zones used in ${var.environment} environment"
  type        = "StringList"
  value       = join(",", var.availability_zones)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-availability-zones"
    }
  )
}
