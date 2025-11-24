# Networking Module - Local Values
# Defines uniform naming convention: <environment>-<project>-<resource>[-<az>]

locals {
  # Base naming prefix
  name_prefix = "${var.environment}-${var.project_name}"

  # VPC naming
  vpc_name = "${local.name_prefix}-vpc"
  igw_name = "${local.name_prefix}-igw"

  # Subnet names with AZ suffix
  public_subnet_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-public-subnet-${substr(az, -2, 2)}"
  ]

  private_subnet_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-private-subnet-${substr(az, -2, 2)}"
  ]

  data_subnet_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-data-subnet-${substr(az, -2, 2)}"
  ]

  # NAT Gateway names with AZ suffix
  nat_gateway_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-nat-${substr(az, -2, 2)}"
  ]

  nat_eip_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-nat-eip-${substr(az, -2, 2)}"
  ]

  # Route table names
  public_route_table_name = "${local.name_prefix}-public-rt"

  private_route_table_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-private-rt-${substr(az, -2, 2)}"
  ]

  data_route_table_names = [
    for idx, az in var.availability_zones :
    "${local.name_prefix}-data-rt-${substr(az, -2, 2)}"
  ]

  # Network ACL names
  public_nacl_name  = "${local.name_prefix}-public-nacl"
  private_nacl_name = "${local.name_prefix}-private-nacl"
  data_nacl_name    = "${local.name_prefix}-data-nacl"

  # VPN Gateway name
  vpn_gateway_name = "${local.name_prefix}-vpn-gateway"

  # VPC Flow Logs names
  flow_log_name        = "${local.name_prefix}-vpc-flow-logs"
  flow_log_group_name  = "/aws/vpc/${local.name_prefix}-flow-logs"
  flow_log_role_name   = "${local.name_prefix}-vpc-flow-logs-role"
  flow_log_policy_name = "${local.name_prefix}-vpc-flow-logs-policy"

  # SSM Parameter Store paths
  ssm_prefix = "/${var.environment}/${var.project_name}/networking"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "networking"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}
