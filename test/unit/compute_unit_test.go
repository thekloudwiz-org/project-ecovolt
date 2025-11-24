package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test Lambda function creation and configuration
func TestLambdaFunctionCreation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.130.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.130.1.0/24", "10.130.2.0/24"},
			"private_subnet_cidrs": []string{"10.130.11.0/24", "10.130.12.0/24"},
			"data_subnet_cidrs":    []string{"10.130.21.0/24", "10.130.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")

	// Create compute module
	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":       "ecovolt",
			"environment":        fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":             vpcID,
			"private_subnet_ids": privateSubnetIDs,
			"lambda_runtime":     "python3.11",
			"lambda_memory_size": 512,
			"lambda_timeout":     60,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify Lambda function was created
	apiFunctionName := terraform.Output(t, computeOptions, "api_handler_function_name")
	assert.NotEmpty(t, apiFunctionName, "API handler function name should not be empty")
	assert.Contains(t, apiFunctionName, "ecovolt", "Function name should contain project name")
	assert.Contains(t, apiFunctionName, uniqueID, "Function name should contain environment ID")

	apiFunctionARN := terraform.Output(t, computeOptions, "api_handler_function_arn")
	assert.NotEmpty(t, apiFunctionARN, "API handler function ARN should not be empty")
	assert.Contains(t, apiFunctionARN, "arn:aws:lambda", "Should be a valid Lambda ARN")
}

// Test API Gateway configuration
func TestAPIGatewayConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.131.0.0/16",
			"availability_zones":   []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":  []string{"10.131.1.0/24", "10.131.2.0/24"},
			"private_subnet_cidrs": []string{"10.131.11.0/24", "10.131.12.0/24"},
			"data_subnet_cidrs":    []string{"10.131.21.0/24", "10.131.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")

	// Create compute module
	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                  vpcID,
			"private_subnet_ids":      privateSubnetIDs,
			"api_gateway_name":        "test-api",
			"api_gateway_stage_name":  "v1",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify API Gateway was created
	apiGatewayID := terraform.Output(t, computeOptions, "api_gateway_id")
	assert.NotEmpty(t, apiGatewayID, "API Gateway ID should not be empty")

	apiGatewayURL := terraform.Output(t, computeOptions, "api_gateway_invoke_url")
	assert.NotEmpty(t, apiGatewayURL, "API Gateway URL should not be empty")
	assert.Contains(t, apiGatewayURL, "execute-api", "URL should be an API Gateway endpoint")
	assert.Contains(t, apiGatewayURL, "v1", "URL should contain stage name")

	apiGatewayStageName := terraform.Output(t, computeOptions, "api_gateway_stage_name")
	assert.Equal(t, "v1", apiGatewayStageName, "Stage name should match configuration")
}

// Test security group rules for VPC functions
func TestSecurityGroupRulesForVPCFunctions(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.132.0.0/16",
			"availability_zones":   []string{"eu-central-1a", "eu-central-1b"},
			"public_subnet_cidrs":  []string{"10.132.1.0/24", "10.132.2.0/24"},
			"private_subnet_cidrs": []string{"10.132.11.0/24", "10.132.12.0/24"},
			"data_subnet_cidrs":    []string{"10.132.21.0/24", "10.132.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")

	// Create compute module
	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":       "ecovolt",
			"environment":        fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":             vpcID,
			"private_subnet_ids": privateSubnetIDs,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify security group was created
	lambdaSGID := terraform.Output(t, computeOptions, "lambda_security_group_id")
	assert.NotEmpty(t, lambdaSGID, "Lambda security group should be created")
	assert.Contains(t, lambdaSGID, "sg-", "Should be a valid security group ID")
}

// Test Lambda IAM role permissions
func TestLambdaIAMRolePermissions(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.133.0.0/16",
			"availability_zones":   []string{"ap-southeast-1a", "ap-southeast-1b"},
			"public_subnet_cidrs":  []string{"10.133.1.0/24", "10.133.2.0/24"},
			"private_subnet_cidrs": []string{"10.133.11.0/24", "10.133.12.0/24"},
			"data_subnet_cidrs":    []string{"10.133.21.0/24", "10.133.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")

	// Create compute module
	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":       "ecovolt",
			"environment":        fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":             vpcID,
			"private_subnet_ids": privateSubnetIDs,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify Lambda execution role was created
	lambdaRoleARN := terraform.Output(t, computeOptions, "lambda_execution_role_arn")
	assert.NotEmpty(t, lambdaRoleARN, "Lambda execution role should be created")
	assert.Contains(t, lambdaRoleARN, "arn:aws:iam", "Should be a valid IAM role ARN")
	assert.Contains(t, lambdaRoleARN, "role/", "Should be an IAM role")
}

// Test CloudWatch Log Group creation
func TestCloudWatchLogGroupCreation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.134.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.134.1.0/24", "10.134.2.0/24"},
			"private_subnet_cidrs": []string{"10.134.11.0/24", "10.134.12.0/24"},
			"data_subnet_cidrs":    []string{"10.134.21.0/24", "10.134.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	privateSubnetIDs := terraform.OutputList(t, networkingOptions, "private_subnet_ids")

	// Create compute module
	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":              "ecovolt",
			"environment":               fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                    vpcID,
			"private_subnet_ids":        privateSubnetIDs,
			"lambda_log_retention_days": 7,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify CloudWatch Log Groups were created
	apiLogGroup := terraform.Output(t, computeOptions, "api_handler_log_group_name")
	assert.NotEmpty(t, apiLogGroup, "API handler log group should be created")
	assert.Contains(t, apiLogGroup, "/aws/lambda/", "Log group should be for Lambda")

	streamLogGroup := terraform.Output(t, computeOptions, "stream_processor_log_group_name")
	assert.NotEmpty(t, streamLogGroup, "Stream processor log group should be created")
	assert.Contains(t, streamLogGroup, "/aws/lambda/", "Log group should be for Lambda")
}
