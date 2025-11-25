# Naming Convention and SSM Parameter Store

## Naming Convention

All resources in the networking module follow a uniform naming convention:

```
<environment>-<project>-<resource>[-<az>]
```

### Components

- **environment**: The deployment environment (dev, staging, prod)
- **project**: The project name (ecovolt)
- **resource**: The resource type (vpc, subnet, nat, igw, etc.)
- **az**: Availability zone suffix (optional, for multi-AZ resources)

### Examples

#### Single Resources
- VPC: `dev-ecovolt-vpc`
- Internet Gateway: `prod-ecovolt-igw`
- Public Route Table: `staging-ecovolt-public-rt`

#### Multi-AZ Resources
- Public Subnet in us-east-1a: `dev-ecovolt-public-subnet-1a`
- NAT Gateway in eu-central-1b: `prod-ecovolt-nat-1b`
- Private Route Table in ap-southeast-1c: `staging-ecovolt-private-rt-1c`

### AZ Suffix Format

The AZ suffix uses the last 2 characters of the availability zone name:
- `us-east-1a` → `1a`
- `eu-central-1b` → `1b`
- `ap-southeast-1c` → `1c`

This keeps names concise while maintaining uniqueness.

## Implementation

The naming convention is implemented in `locals.tf`:

```hcl
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
  
  # ... more naming definitions
}
```

All resources use these local values for their `Name` tag:

```hcl
resource "aws_vpc" "main" {
  # ...
  tags = merge(
    local.common_tags,
    {
      Name = local.vpc_name
    }
  )
}
```

## SSM Parameter Store

All networking resource IDs are stored in AWS Systems Manager Parameter Store for easy reference by other modules and configurations.

### Parameter Path Structure

```
/<environment>/<project>/networking/<parameter_name>
```

### Example Paths

- VPC ID: `/dev/ecovolt/networking/vpc_id`
- Public Subnet IDs: `/prod/ecovolt/networking/public_subnet_ids`
- NAT Gateway ID (AZ 1a): `/staging/ecovolt/networking/nat_gateway_id_1a`

### Stored Parameters

#### Core Resources
- `vpc_id` - VPC identifier
- `vpc_cidr` - VPC CIDR block
- `internet_gateway_id` - Internet Gateway ID
- `flow_log_id` - VPC Flow Log ID
- `flow_log_group_name` - CloudWatch Log Group name

#### Subnet IDs (Aggregated)
- `public_subnet_ids` - All public subnet IDs (StringList)
- `private_subnet_ids` - All private subnet IDs (StringList)
- `data_subnet_ids` - All data subnet IDs (StringList)

#### Subnet IDs (Individual per AZ)
- `public_subnet_id_1a` - Public subnet in AZ 1a
- `public_subnet_id_1b` - Public subnet in AZ 1b
- `private_subnet_id_1a` - Private subnet in AZ 1a
- `private_subnet_id_1b` - Private subnet in AZ 1b
- `data_subnet_id_1a` - Data subnet in AZ 1a
- `data_subnet_id_1b` - Data subnet in AZ 1b

#### NAT Gateway Resources
- `nat_gateway_ids` - All NAT Gateway IDs (StringList)
- `nat_gateway_id_1a` - NAT Gateway in AZ 1a
- `nat_gateway_id_1b` - NAT Gateway in AZ 1b
- `nat_gateway_ips` - All NAT Gateway Elastic IPs (StringList)

#### Route Tables
- `public_route_table_id` - Public route table ID
- `private_route_table_ids` - All private route table IDs (StringList)
- `data_route_table_ids` - All data route table IDs (StringList)

#### Optional Resources
- `vpn_gateway_id` - VPN Gateway ID (if enabled)

#### Metadata
- `availability_zones` - List of AZs used (StringList)

### Parameter Types

- **String**: Single value (e.g., VPC ID)
- **StringList**: Comma-separated values (e.g., subnet IDs)

### Usage Examples

#### Terraform Data Source

```hcl
# Retrieve VPC ID from SSM
data "aws_ssm_parameter" "vpc_id" {
  name = "/dev/ecovolt/networking/vpc_id"
}

# Use in resource
resource "aws_security_group" "example" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  # ...
}
```

#### Retrieve Multiple Subnet IDs

```hcl
# Retrieve private subnet IDs
data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/prod/ecovolt/networking/private_subnet_ids"
}

# Split into list
locals {
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}

# Use in resource
resource "aws_db_subnet_group" "main" {
  subnet_ids = local.private_subnet_ids
  # ...
}
```

#### AWS CLI

```bash
# Get VPC ID
aws ssm get-parameter \
  --name "/dev/ecovolt/networking/vpc_id" \
  --query "Parameter.Value" \
  --output text

# Get all public subnet IDs
aws ssm get-parameter \
  --name "/dev/ecovolt/networking/public_subnet_ids" \
  --query "Parameter.Value" \
  --output text

# Get specific subnet ID for AZ 1a
aws ssm get-parameter \
  --name "/dev/ecovolt/networking/public_subnet_id_1a" \
  --query "Parameter.Value" \
  --output text
```

#### Python (Boto3)

```python
import boto3

ssm = boto3.client('ssm')

# Get VPC ID
response = ssm.get_parameter(Name='/dev/ecovolt/networking/vpc_id')
vpc_id = response['Parameter']['Value']

# Get private subnet IDs
response = ssm.get_parameter(Name='/dev/ecovolt/networking/private_subnet_ids')
subnet_ids = response['Parameter']['Value'].split(',')
```

### Benefits

1. **Decoupling**: Other modules don't need direct Terraform outputs
2. **Cross-Stack References**: Access networking resources from any AWS service
3. **Runtime Access**: Applications can retrieve network configuration at runtime
4. **Auditability**: All parameters are tagged and versioned
5. **Consistency**: Single source of truth for network resource IDs

### Security Considerations

- All parameters use type `String` or `StringList` (not `SecureString`)
- Resource IDs are not sensitive data
- Parameters are tagged with environment and project for organization
- IAM policies can restrict access to specific parameter paths

### Cost

- SSM Parameter Store Standard parameters: **Free**
- No additional cost for storing these parameters
- Advanced parameters (not used here) would incur charges

## Module Outputs

The networking module provides SSM parameter names as outputs:

```hcl
output "ssm_vpc_id_parameter" {
  description = "SSM Parameter name for VPC ID"
  value       = aws_ssm_parameter.vpc_id.name
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for networking resources"
  value       = local.ssm_prefix
}
```

This allows other modules to reference the parameter names dynamically:

```hcl
module "networking" {
  source = "./modules/networking"
  # ...
}

data "aws_ssm_parameter" "vpc_id" {
  name = module.networking.ssm_vpc_id_parameter
}
```

## Best Practices

### Naming
1. Always use the naming convention for consistency
2. Include AZ suffix for multi-AZ resources
3. Use descriptive resource names (e.g., `public-subnet` not just `subnet`)
4. Keep names concise but clear

### SSM Parameters
1. Use StringList for multiple values (easier to parse)
2. Store both aggregated and individual resource IDs
3. Include metadata (AZs, CIDR blocks) for reference
4. Tag all parameters with environment and project
5. Use consistent parameter naming across modules

### Terraform
1. Define all naming in `locals.tf`
2. Use `local.common_tags` for consistent tagging
3. Reference locals in resource definitions
4. Export SSM parameter names as outputs

## Migration from Old Naming

If you have existing resources with different naming:

1. Update `locals.tf` to match your current naming
2. Or use Terraform `moved` blocks to rename resources
3. Update SSM parameters to reflect new names
4. Update any hardcoded references in other modules

## Examples

### Development Environment

```
dev-ecovolt-vpc
dev-ecovolt-igw
dev-ecovolt-public-subnet-1a
dev-ecovolt-public-subnet-1b
dev-ecovolt-nat-1a
dev-ecovolt-nat-1b
dev-ecovolt-private-rt-1a
```

SSM Parameters:
```
/dev/ecovolt/networking/vpc_id
/dev/ecovolt/networking/public_subnet_ids
/dev/ecovolt/networking/nat_gateway_id_1a
```

### Production Environment

```
prod-ecovolt-vpc
prod-ecovolt-igw
prod-ecovolt-public-subnet-1a
prod-ecovolt-public-subnet-1b
prod-ecovolt-public-subnet-1c
prod-ecovolt-nat-1a
prod-ecovolt-nat-1b
prod-ecovolt-nat-1c
```

SSM Parameters:
```
/prod/ecovolt/networking/vpc_id
/prod/ecovolt/networking/public_subnet_ids
/prod/ecovolt/networking/nat_gateway_id_1a
/prod/ecovolt/networking/nat_gateway_id_1b
/prod/ecovolt/networking/nat_gateway_id_1c
```

## Troubleshooting

### Parameter Not Found

If you get "Parameter not found" errors:

1. Verify the environment and project name match
2. Check the parameter path format
3. Ensure the networking module has been applied
4. Verify IAM permissions for SSM access

### Incorrect Values

If parameter values are incorrect:

1. Check Terraform state for resource IDs
2. Verify the SSM parameter was created correctly
3. Re-apply the networking module if needed
4. Check for parameter name conflicts

### Naming Conflicts

If you see naming conflicts:

1. Ensure environment names are unique
2. Check for duplicate resource definitions
3. Verify AZ suffixes are correct
4. Review `locals.tf` for naming logic

## References

- [AWS SSM Parameter Store Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [Terraform AWS SSM Parameter Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)
- [Terraform AWS SSM Parameter Data Source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter)
