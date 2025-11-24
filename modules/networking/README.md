# Networking Module

This module creates a production-ready, multi-tier VPC architecture with public, private, and data subnets across multiple availability zones.

## Features

- **Multi-AZ VPC**: Deploys resources across multiple availability zones for high availability
- **Three-Tier Architecture**: Separates resources into public, private, and data subnet tiers
- **NAT Gateways**: Provides internet access for private subnets (one NAT Gateway per AZ)
- **Network ACLs**: Implements subnet-level security controls
- **VPC Flow Logs**: Enables network traffic monitoring and security analysis
- **Internet Gateway**: Provides internet connectivity for public subnets
- **Route Tables**: Configures appropriate routing for each subnet tier
- **VPN Gateway**: Optional VPN connectivity support

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC                                  │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ AZ-1         │  │ AZ-2         │  │ AZ-3         │      │
│  │              │  │              │  │              │      │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │
│  │ │ Public   │ │  │ │ Public   │ │  │ │ Public   │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ │ + NAT GW │ │  │ │ + NAT GW │ │  │ │ + NAT GW │ │      │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │
│  │              │  │              │  │              │      │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │
│  │ │ Private  │ │  │ │ Private  │ │  │ │ Private  │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │
│  │              │  │              │  │              │      │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │
│  │ │ Data     │ │  │ │ Data     │ │  │ │ Data     │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         │                                              ▲
         │                                              │
    Internet Gateway                            VPC Flow Logs
```

## Subnet Tiers

### Public Subnets
- **Purpose**: Internet-facing resources (ALB, NAT Gateways, bastion hosts)
- **Internet Access**: Direct via Internet Gateway
- **Network ACL**: Allows HTTP/HTTPS inbound, SSH from VPC, ephemeral ports
- **Use Cases**: Load balancers, NAT Gateways, public-facing services

### Private Subnets
- **Purpose**: Application workloads (ECS tasks, Lambda functions, application servers)
- **Internet Access**: Via NAT Gateway in public subnet
- **Network ACL**: Allows all traffic from VPC, ephemeral ports from internet
- **Use Cases**: Backend services, application servers, compute resources

### Data Subnets
- **Purpose**: Database instances and data stores
- **Internet Access**: None (isolated from internet)
- **Network ACL**: Only allows traffic from within VPC
- **Use Cases**: RDS, ElastiCache, Timestream, data storage

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  project_name         = "ecovolt"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  data_subnet_cidrs    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  environment          = "prod"

  tags = {
    Project   = "EcoVolt"
    ManagedBy = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | "ecovolt" | no |
| vpc_cidr | CIDR block for VPC | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | - | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | - | yes |
| data_subnet_cidrs | CIDR blocks for data subnets | list(string) | - | yes |
| enable_nat_gateway | Enable NAT gateways | bool | true | no |
| enable_vpn_gateway | Enable VPN gateway | bool | false | no |
| environment | Environment name | string | - | yes |
| tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC identifier |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| data_subnet_ids | List of data subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_ips | Elastic IPs of NAT gateways |
| internet_gateway_id | Internet Gateway ID |
| flow_log_id | VPC Flow Log ID |
| flow_log_group_name | CloudWatch Log Group name for Flow Logs |
| ssm_vpc_id_parameter | SSM Parameter name for VPC ID |
| ssm_public_subnet_ids_parameter | SSM Parameter name for public subnet IDs |
| ssm_private_subnet_ids_parameter | SSM Parameter name for private subnet IDs |
| ssm_data_subnet_ids_parameter | SSM Parameter name for data subnet IDs |
| ssm_parameter_prefix | SSM Parameter Store prefix |

## Naming Convention

All resources follow a uniform naming convention: `<environment>-<project>-<resource>[-<az>]`

Examples:
- VPC: `dev-ecovolt-vpc`
- Public Subnet in us-east-1a: `prod-ecovolt-public-subnet-1a`
- NAT Gateway in eu-central-1b: `staging-ecovolt-nat-1b`

See [NAMING_AND_SSM.md](./NAMING_AND_SSM.md) for complete details.

## SSM Parameter Store

All networking resource IDs are automatically stored in AWS Systems Manager Parameter Store for easy reference by other modules:

- VPC ID: `/<environment>/<project>/networking/vpc_id`
- Public Subnet IDs: `/<environment>/<project>/networking/public_subnet_ids`
- NAT Gateway IDs: `/<environment>/<project>/networking/nat_gateway_ids`

Example usage:
```hcl
data "aws_ssm_parameter" "vpc_id" {
  name = "/dev/ecovolt/networking/vpc_id"
}

resource "aws_security_group" "example" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}
```

See [NAMING_AND_SSM.md](./NAMING_AND_SSM.md) for complete parameter list and usage examples.

## Security Considerations

1. **Network Isolation**: Data subnets have no internet access and only accept traffic from VPC
2. **Least Privilege**: Network ACLs implement defense-in-depth security
3. **Flow Logs**: All network traffic is logged for security analysis
4. **Multi-AZ NAT**: Each AZ has its own NAT Gateway for fault tolerance
5. **Encryption**: VPC Flow Logs are stored in CloudWatch with encryption at rest
6. **SSM Parameters**: Resource IDs stored in SSM for secure cross-module reference

## Cost Optimization

- **NAT Gateways**: Most expensive component (~$0.045/hour per gateway + data transfer)
- **VPC Flow Logs**: Storage costs in CloudWatch Logs (30-day retention)
- **Elastic IPs**: Free when associated with running NAT Gateways

To reduce costs in non-production environments:
- Set `enable_nat_gateway = false` if private subnets don't need internet access
- Reduce number of availability zones
- Use shorter log retention periods

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Validation

The module includes input validation for:
- Valid CIDR blocks for VPC and subnets
- Minimum 2 availability zones for high availability
- Matching number of subnet CIDRs and availability zones

## Examples

### Development Environment (Minimal)
```hcl
module "networking" {
  source = "./modules/networking"

  project_name         = "ecovolt"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  data_subnet_cidrs    = ["10.0.21.0/24", "10.0.22.0/24"]
  enable_nat_gateway   = false  # Cost savings
  enable_vpn_gateway   = false
  environment          = "dev"

  tags = {
    Environment = "Development"
  }
}
```

### Production Environment (Full HA)
```hcl
module "networking" {
  source = "./modules/networking"

  project_name         = "ecovolt"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  data_subnet_cidrs    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  environment          = "prod"

  tags = {
    Environment = "Production"
    Compliance  = "Required"
  }
}
```

## Troubleshooting

### CIDR Overlap Errors
If you see CIDR overlap errors, ensure:
- Subnet CIDRs don't overlap with each other
- Subnet CIDRs are within the VPC CIDR range
- No conflicts with existing VPCs in peering relationships

### NAT Gateway Connectivity Issues
If private subnets can't reach the internet:
- Verify NAT Gateways are in "available" state
- Check route tables have correct NAT Gateway routes
- Verify security groups allow outbound traffic
- Check network ACLs allow ephemeral port return traffic

### VPC Flow Logs Not Appearing
If flow logs aren't being captured:
- Verify IAM role has correct permissions
- Check CloudWatch Log Group exists
- Allow 10-15 minutes for initial log delivery
- Verify traffic is actually flowing through the VPC

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
