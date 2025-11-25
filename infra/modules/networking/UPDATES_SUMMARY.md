# Networking Module Updates - Naming Convention and SSM

## Summary

Updated the networking module to implement a uniform naming convention and store all resource IDs in AWS Systems Manager Parameter Store for cross-module reference.

## Changes Made

### 1. New File: `locals.tf`

Created a centralized locals file that defines:

- **Naming Convention**: `<environment>-<project>-<resource>[-<az>]`
- **Base Prefix**: `${var.environment}-${var.project_name}`
- **Resource Names**: All resource names generated from locals
- **SSM Prefix**: `/${var.environment}/${var.project_name}/networking`
- **Common Tags**: Merged tags with module, environment, and project

Example naming:
```
dev-ecovolt-vpc
prod-ecovolt-public-subnet-1a
staging-ecovolt-nat-1b
```

### 2. New File: `ssm.tf`

Created SSM Parameter Store resources for all networking outputs:

**Stored Parameters** (25+ parameters):
- VPC ID and CIDR
- Subnet IDs (aggregated and per-AZ)
- NAT Gateway IDs and IPs
- Route Table IDs
- Internet Gateway ID
- VPC Flow Log details
- VPN Gateway ID (if enabled)
- Availability Zones

**Parameter Path Structure**:
```
/<environment>/<project>/networking/<parameter_name>
```

Examples:
```
/dev/ecovolt/networking/vpc_id
/prod/ecovolt/networking/public_subnet_ids
/staging/ecovolt/networking/nat_gateway_id_1a
```

### 3. Updated: `main.tf`

Replaced all hardcoded naming with local references:

**Before**:
```hcl
tags = merge(
  var.tags,
  {
    Name = "${var.environment}-vpc"
  }
)
```

**After**:
```hcl
tags = merge(
  local.common_tags,
  {
    Name = local.vpc_name
  }
)
```

All resources now use:
- `local.common_tags` for consistent tagging
- Local naming variables for Name tags
- AZ tags for multi-AZ resources

### 4. Updated: `variables.tf`

Added new variable:
```hcl
variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}
```

### 5. Updated: `outputs.tf`

Added SSM parameter name outputs:
- `ssm_vpc_id_parameter`
- `ssm_public_subnet_ids_parameter`
- `ssm_private_subnet_ids_parameter`
- `ssm_data_subnet_ids_parameter`
- `ssm_nat_gateway_ids_parameter`
- `ssm_parameter_prefix`

### 6. New Documentation: `NAMING_AND_SSM.md`

Comprehensive guide covering:
- Naming convention details and examples
- SSM Parameter Store structure
- Usage examples (Terraform, AWS CLI, Python)
- Best practices
- Troubleshooting

### 7. Updated: `README.md`

Added sections for:
- Naming convention overview
- SSM Parameter Store usage
- Updated examples with `project_name` variable
- Updated inputs/outputs tables

### 8. Updated: Root `main.tf`

Added `project_name` parameter to networking module call:
```hcl
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  # ... other variables
}
```

## Benefits

### 1. Consistent Naming
- All resources follow the same pattern
- Easy to identify resources by environment and project
- AZ suffix makes multi-AZ resources clear
- Predictable naming for automation

### 2. Cross-Module Reference
- Other modules can retrieve network IDs from SSM
- No need for complex Terraform output dependencies
- Works across different Terraform states
- Enables runtime configuration retrieval

### 3. Operational Excellence
- Applications can retrieve network config at runtime
- Easy to query resources via AWS CLI
- Single source of truth for network IDs
- Supports disaster recovery and failover scenarios

### 4. Cost Efficiency
- SSM Standard parameters are free
- No additional infrastructure required
- Reduces complexity of Terraform state management

## Usage Examples

### Terraform Module Call

```hcl
module "networking" {
  source = "./modules/networking"

  project_name         = "ecovolt"
  environment          = "prod"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  data_subnet_cidrs    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  enable_nat_gateway   = true
  enable_vpn_gateway   = false

  tags = {
    ManagedBy = "Terraform"
  }
}
```

### Retrieve VPC ID from SSM

```hcl
# In another module or configuration
data "aws_ssm_parameter" "vpc_id" {
  name = "/prod/ecovolt/networking/vpc_id"
}

resource "aws_security_group" "app" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  # ...
}
```

### Retrieve Subnet IDs

```hcl
data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/prod/ecovolt/networking/private_subnet_ids"
}

locals {
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}

resource "aws_db_subnet_group" "main" {
  subnet_ids = local.private_subnet_ids
  # ...
}
```

### AWS CLI

```bash
# Get VPC ID
aws ssm get-parameter \
  --name "/prod/ecovolt/networking/vpc_id" \
  --query "Parameter.Value" \
  --output text

# Get all private subnet IDs
aws ssm get-parameter \
  --name "/prod/ecovolt/networking/private_subnet_ids" \
  --query "Parameter.Value" \
  --output text
```

## Resource Naming Examples

### Development Environment
```
dev-ecovolt-vpc
dev-ecovolt-igw
dev-ecovolt-public-subnet-1a
dev-ecovolt-public-subnet-1b
dev-ecovolt-private-subnet-1a
dev-ecovolt-private-subnet-1b
dev-ecovolt-data-subnet-1a
dev-ecovolt-data-subnet-1b
dev-ecovolt-nat-1a
dev-ecovolt-nat-1b
dev-ecovolt-nat-eip-1a
dev-ecovolt-nat-eip-1b
dev-ecovolt-public-rt
dev-ecovolt-private-rt-1a
dev-ecovolt-private-rt-1b
dev-ecovolt-data-rt-1a
dev-ecovolt-data-rt-1b
dev-ecovolt-public-nacl
dev-ecovolt-private-nacl
dev-ecovolt-data-nacl
dev-ecovolt-vpc-flow-logs
dev-ecovolt-vpc-flow-logs-role
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
prod-ecovolt-vpn-gateway
```

## SSM Parameter Examples

### Development Environment
```
/dev/ecovolt/networking/vpc_id
/dev/ecovolt/networking/vpc_cidr
/dev/ecovolt/networking/public_subnet_ids
/dev/ecovolt/networking/private_subnet_ids
/dev/ecovolt/networking/data_subnet_ids
/dev/ecovolt/networking/public_subnet_id_1a
/dev/ecovolt/networking/public_subnet_id_1b
/dev/ecovolt/networking/private_subnet_id_1a
/dev/ecovolt/networking/private_subnet_id_1b
/dev/ecovolt/networking/data_subnet_id_1a
/dev/ecovolt/networking/data_subnet_id_1b
/dev/ecovolt/networking/nat_gateway_ids
/dev/ecovolt/networking/nat_gateway_id_1a
/dev/ecovolt/networking/nat_gateway_id_1b
/dev/ecovolt/networking/nat_gateway_ips
/dev/ecovolt/networking/internet_gateway_id
/dev/ecovolt/networking/public_route_table_id
/dev/ecovolt/networking/private_route_table_ids
/dev/ecovolt/networking/data_route_table_ids
/dev/ecovolt/networking/flow_log_id
/dev/ecovolt/networking/flow_log_group_name
/dev/ecovolt/networking/availability_zones
```

## Migration Guide

If you have existing networking resources:

### Option 1: Update Naming in Locals

Modify `locals.tf` to match your existing naming:
```hcl
locals {
  vpc_name = "my-existing-vpc-name"
  # ... other names
}
```

### Option 2: Use Terraform Moved Blocks

Rename resources without recreating:
```hcl
moved {
  from = aws_vpc.main
  to   = aws_vpc.main
}
```

### Option 3: Recreate Resources

If acceptable, destroy and recreate with new naming:
```bash
terraform destroy -target=module.networking
terraform apply
```

## Testing

All existing tests remain valid. The naming changes are internal to the module and don't affect the module's interface or behavior.

Property-based tests and unit tests will now create resources with the new naming convention.

## Backward Compatibility

The module interface remains backward compatible:
- All existing outputs are unchanged
- New SSM outputs are additive
- `project_name` variable has a default value

Existing module calls will work without changes, but should add `project_name` for consistency.

## Next Steps

1. **Apply Changes**: Run `terraform plan` to preview naming changes
2. **Review SSM Parameters**: Verify parameters are created correctly
3. **Update Other Modules**: Migrate other modules to use SSM parameters
4. **Update Documentation**: Document SSM parameter usage in other modules
5. **Test Integration**: Verify cross-module references work correctly

## Files Modified

```
modules/networking/
├── locals.tf                 # NEW - Naming convention and locals
├── ssm.tf                    # NEW - SSM Parameter Store resources
├── main.tf                   # UPDATED - Use local naming
├── variables.tf              # UPDATED - Add project_name variable
├── outputs.tf                # UPDATED - Add SSM parameter outputs
├── README.md                 # UPDATED - Document naming and SSM
├── NAMING_AND_SSM.md         # NEW - Comprehensive guide
└── UPDATES_SUMMARY.md        # NEW - This file

main.tf                       # UPDATED - Pass project_name to module
```

## Validation

All files validated with no diagnostics:
- ✅ `locals.tf` - No issues
- ✅ `ssm.tf` - No issues
- ✅ `main.tf` - No issues
- ✅ `variables.tf` - No issues
- ✅ `outputs.tf` - No issues

## References

- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [Terraform AWS SSM Parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)
- [Terraform Locals](https://www.terraform.io/language/values/locals)
