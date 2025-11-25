# EcoVolt Infrastructure Tests

This directory contains property-based tests and unit tests for the EcoVolt AWS infrastructure using Terratest.

## Test Structure

```
test/
├── properties/          # Property-based tests (100+ iterations each)
│   └── networking_properties_test.go
├── unit/               # Unit tests for specific configurations
│   └── networking_unit_test.go
├── integration/        # End-to-end integration tests
├── helpers/            # Test utilities and helper functions
├── go.mod              # Go module dependencies
└── README.md           # This file
```

## Prerequisites

- Go 1.21 or higher
- Terraform 1.5 or higher
- AWS credentials configured
- AWS account with permissions to create VPC resources

## Running Tests

### Install Dependencies

```bash
cd test
go mod download
```

### Run All Tests

```bash
go test -v ./...
```

### Run Property Tests Only

```bash
go test -v ./properties/
```

### Run Unit Tests Only

```bash
go test -v ./unit/
```

### Run Specific Test

```bash
go test -v ./properties/ -run TestProperty1_MultiTierSubnetPlacement
```

### Run Tests in Parallel

```bash
go test -v -parallel 4 ./...
```

## Property-Based Tests

Property-based tests verify that correctness properties hold across many different input configurations. Each property test runs 100 iterations with randomly generated:

- AWS regions
- Availability zone counts (2-4)
- VPC CIDR blocks
- Subnet configurations

### Networking Properties

#### Property 1: Multi-tier Subnet Placement
**Validates: Requirements 1.2**

Verifies that resources are correctly placed in appropriate subnet tiers:
- Internet-facing resources (NAT Gateways) in public subnets
- Backend resources in private subnets
- Data resources in isolated data subnets

#### Property 2: Network Security Controls
**Validates: Requirements 1.4**

Verifies that network security controls are properly configured:
- VPC Flow Logs enabled for monitoring
- Route tables configured for each tier
- Internet Gateway for public subnets
- NAT Gateways for private subnet internet access
- Data subnets isolated from internet

## Unit Tests

Unit tests verify specific infrastructure configurations and edge cases:

- VPC creation with valid CIDR blocks
- Subnet creation across specified AZs
- Route table associations
- NAT Gateway configuration
- Network ACL rules
- VPC Flow Logs setup

## Test Configuration

Tests use the following AWS regions for validation:
- us-east-1 (N. Virginia)
- us-west-2 (Oregon)
- eu-central-1 (Frankfurt)
- eu-west-1 (Ireland)
- ap-southeast-1 (Singapore)

## Cost Considerations

**WARNING**: Running these tests will create real AWS resources and incur costs.

Estimated costs per test run:
- VPC: Free
- Subnets: Free
- Internet Gateway: Free
- NAT Gateways: ~$0.045/hour per gateway
- VPC Flow Logs: CloudWatch Logs storage costs

Each property test iteration creates resources for ~5-10 minutes, then destroys them.

### Cost Optimization Tips

1. Run tests in parallel to reduce total time
2. Use `t.Parallel()` to run test iterations concurrently
3. Set AWS_REGION to a low-cost region
4. Monitor AWS costs during test runs
5. Ensure cleanup (defer terraform.Destroy) always runs

## Cleanup

Tests automatically clean up resources using `defer terraform.Destroy()`. If a test fails or is interrupted:

```bash
# List Terraform state files
find . -name "terraform.tfstate"

# Manually destroy resources
cd <test_directory>
terraform destroy -auto-approve
```

## Troubleshooting

### Test Timeout

If tests timeout, increase the timeout:

```bash
go test -v -timeout 30m ./properties/
```

### AWS Rate Limiting

If you hit AWS API rate limits:

1. Reduce parallel test count: `go test -parallel 2`
2. Add delays between test iterations
3. Use different AWS regions

### Resource Cleanup Failures

If resources aren't cleaned up:

1. Check AWS Console for orphaned resources
2. Look for resources tagged with `Test: Property1` or `Test: Property2`
3. Manually delete VPCs and associated resources

### Terraform State Lock

If you see state lock errors:

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Infrastructure Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Run Tests
        run: |
          cd test
          go mod download
          go test -v -timeout 30m ./...
```

## Best Practices

1. **Always use defer terraform.Destroy()** to ensure cleanup
2. **Use unique IDs** for resource naming to avoid conflicts
3. **Run tests in isolated AWS accounts** to prevent interference
4. **Monitor AWS costs** during test development
5. **Use t.Parallel()** for faster test execution
6. **Set appropriate timeouts** for long-running tests
7. **Tag all test resources** for easy identification and cleanup

## References

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Go Testing Package](https://pkg.go.dev/testing)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
