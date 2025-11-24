# Testing Guide for EcoVolt Infrastructure

## Overview

This guide explains how to run the property-based tests and unit tests for the EcoVolt AWS infrastructure networking module.

## What Was Implemented

### Networking Module (`modules/networking/`)

A production-ready, multi-tier VPC architecture with:

- **VPC**: Configurable CIDR block with DNS support
- **Three-Tier Subnets**: Public, Private, and Data subnets across multiple AZs
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: One per AZ for private subnet internet access (high availability)
- **Route Tables**: Properly configured for each subnet tier
- **Network ACLs**: Subnet-level security controls for each tier
- **VPC Flow Logs**: Network traffic monitoring and security analysis
- **VPN Gateway**: Optional VPN connectivity support

### Property-Based Tests

Two property-based tests that run 100 iterations each with randomized inputs:

1. **Property 1: Multi-tier Subnet Placement** (`TestProperty1_MultiTierSubnetPlacement`)
   - Validates: Requirements 1.2
   - Verifies resources are correctly placed in appropriate subnet tiers
   - Tests with random AWS regions, AZ counts (2-4), and VPC CIDRs

2. **Property 2: Network Security Controls** (`TestProperty2_NetworkSecurityControls`)
   - Validates: Requirements 1.4
   - Verifies network security controls are properly configured
   - Tests VPC Flow Logs, route tables, NAT Gateways, and Internet Gateway

### Unit Tests

Nine unit tests covering specific configurations:

1. VPC creation with valid CIDR blocks
2. Subnet creation across specified AZs
3. Route table associations
4. NAT Gateway configuration
5. NAT Gateway disabled configuration
6. VPC Flow Logs configuration
7. Internet Gateway configuration
8. VPN Gateway configuration
9. Minimum AZ configuration (2 AZs)

## Prerequisites

Before running tests, ensure you have:

1. **Go 1.21+** installed
   ```bash
   # macOS
   brew install go
   
   # Linux
   wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

2. **Terraform 1.5+** installed
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **AWS Credentials** configured
   ```bash
   # Configure AWS CLI
   aws configure
   
   # Or set environment variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

4. **AWS Permissions** - Your AWS account needs permissions to create:
   - VPCs, Subnets, Route Tables
   - Internet Gateways, NAT Gateways
   - Elastic IPs
   - Network ACLs
   - VPC Flow Logs
   - CloudWatch Log Groups
   - IAM Roles (for Flow Logs)

## Installation

1. Navigate to the test directory:
   ```bash
   cd test
   ```

2. Download Go dependencies:
   ```bash
   go mod download
   ```

3. Verify installation:
   ```bash
   go version
   terraform version
   aws sts get-caller-identity
   ```

## Running Tests

### Quick Start - Run All Tests

```bash
cd test
go test -v -timeout 60m ./...
```

### Run Property Tests Only

```bash
cd test
go test -v -timeout 60m ./properties/
```

This will run 200 test iterations (100 for each property test).

### Run Unit Tests Only

```bash
cd test
go test -v -timeout 30m ./unit/
```

This will run 9 unit tests with specific configurations.

### Run Specific Test

```bash
cd test
go test -v -timeout 30m ./properties/ -run TestProperty1_MultiTierSubnetPlacement
```

### Run Tests in Parallel

To speed up execution, run tests in parallel:

```bash
cd test
go test -v -timeout 60m -parallel 4 ./...
```

**Note**: Be careful with parallel execution as it will create multiple AWS resources simultaneously, which may hit AWS API rate limits or increase costs.

## Understanding Test Output

### Successful Test Output

```
=== RUN   TestProperty1_MultiTierSubnetPlacement
=== RUN   TestProperty1_MultiTierSubnetPlacement/Iteration_0
=== PAUSE TestProperty1_MultiTierSubnetPlacement/Iteration_0
...
=== CONT  TestProperty1_MultiTierSubnetPlacement/Iteration_0
    terraform_test.go:45: Running command terraform with args [init -upgrade=false]
    terraform_test.go:45: Running command terraform with args [apply -auto-approve]
    terraform_test.go:45: Running command terraform with args [output -json]
    terraform_test.go:45: Running command terraform with args [destroy -auto-approve]
--- PASS: TestProperty1_MultiTierSubnetPlacement (300.00s)
    --- PASS: TestProperty1_MultiTierSubnetPlacement/Iteration_0 (150.00s)
```

### Failed Test Output

If a test fails, you'll see assertion errors:

```
--- FAIL: TestProperty1_MultiTierSubnetPlacement (150.00s)
    --- FAIL: TestProperty1_MultiTierSubnetPlacement/Iteration_0 (150.00s)
        networking_properties_test.go:65: 
            Error: Should have one public subnet per AZ
            Expected: 3
            Actual: 2
```

## Cost Considerations

**⚠️ WARNING**: Running these tests creates real AWS resources and incurs costs!

### Estimated Costs Per Test Run

- **VPC, Subnets, Route Tables**: Free
- **Internet Gateway**: Free
- **NAT Gateways**: ~$0.045/hour per gateway × number of AZs
- **Elastic IPs**: Free when attached to NAT Gateways
- **VPC Flow Logs**: CloudWatch Logs storage (~$0.50/GB)

### Example Cost Calculation

For a single property test iteration with 3 AZs:
- 3 NAT Gateways × $0.045/hour × 0.15 hours (9 minutes) = ~$0.02
- VPC Flow Logs storage: negligible for short tests
- **Total per iteration**: ~$0.02

For 200 property test iterations:
- **Total estimated cost**: ~$4.00

### Cost Optimization Tips

1. **Run fewer iterations during development**:
   ```go
   // In networking_properties_test.go, change:
   for i := 0; i < 100; i++ {
   // To:
   for i := 0; i < 10; i++ {
   ```

2. **Disable NAT Gateways for some tests**:
   ```go
   "enable_nat_gateway": false,
   ```

3. **Use fewer AZs**:
   ```go
   azCount := 2  // Instead of random 2-4
   ```

4. **Run tests in parallel** to reduce total time

5. **Use a dedicated test AWS account** with budget alerts

## Troubleshooting

### Test Timeout

If tests timeout, increase the timeout:

```bash
go test -v -timeout 90m ./properties/
```

### AWS Rate Limiting

If you see "Rate exceeded" errors:

1. Reduce parallel test count:
   ```bash
   go test -v -parallel 2 ./...
   ```

2. Add delays between iterations (modify test code)

3. Use different AWS regions for different tests

### Resource Cleanup Failures

If resources aren't cleaned up after a test failure:

1. Check AWS Console for resources tagged with `Test: Property1` or `Test: Property2`

2. Find the Terraform state directory:
   ```bash
   find test -name "terraform.tfstate"
   ```

3. Manually destroy resources:
   ```bash
   cd <test_directory>
   terraform destroy -auto-approve
   ```

### Terraform State Lock

If you see "Error acquiring the state lock":

```bash
# List DynamoDB locks (if using S3 backend with DynamoDB)
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Go Module Issues

If you see "cannot find module" errors:

```bash
cd test
go mod tidy
go mod download
```

## Interpreting Test Results

### Property Test Success Criteria

A property test passes when ALL 100 iterations pass, meaning:

- Resources are created successfully
- All assertions pass
- Resources are cleaned up successfully

If even one iteration fails, the entire property test fails.

### What Property Tests Validate

**Property 1** validates that:
- Public, private, and data subnets are created in correct tiers
- One subnet per AZ per tier
- NAT Gateways are placed in public subnets
- All subnet IDs are unique

**Property 2** validates that:
- VPC Flow Logs are enabled
- Route tables are configured for each tier
- Internet Gateway exists
- NAT Gateways exist for private subnet access
- Data subnets are isolated (no NAT Gateway routes)

## Next Steps

After running tests successfully:

1. **Review test results** to ensure all properties hold
2. **Check AWS costs** in the AWS Billing Console
3. **Verify resource cleanup** in the AWS Console
4. **Proceed to next task** in the implementation plan

## CI/CD Integration

To run these tests in CI/CD:

1. Set up AWS credentials as secrets
2. Install Go and Terraform in CI environment
3. Run tests with appropriate timeout
4. Ensure cleanup runs even on failure

Example GitHub Actions workflow:

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
          go test -v -timeout 60m ./...
```

## Support

If you encounter issues:

1. Check the test output for specific error messages
2. Review AWS CloudWatch Logs for VPC Flow Logs
3. Check Terraform state files for resource status
4. Consult the [Terratest documentation](https://terratest.gruntwork.io/)
5. Review the [AWS VPC documentation](https://docs.aws.amazon.com/vpc/)

## References

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Go Testing Package](https://pkg.go.dev/testing)
