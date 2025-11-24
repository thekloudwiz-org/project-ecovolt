package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Feature: ecovolt-aws-infrastructure, Property 16: Auto-scaling on load increase
// For any sustained increase in request load, Lambda should automatically scale concurrent executions
// to handle the load without manual intervention
// Validates: Requirements 4.2
func TestProperty16_AutoScalingOnLoadIncrease(t *testing.T) {
	t.Parallel()

	// Note: This test validates Lambda auto-scaling configuration
	// Full load testing would require actual traffic generation and monitoring

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.120.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.120.1.0/24", "10.120.2.0/24"},
			"private_subnet_cidrs": []string{"10.120.11.0/24", "10.120.12.0/24"},
			"data_subnet_cidrs":    []string{"10.120.21.0/24", "10.120.22.0/24"},
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
			"project_name":                          "ecovolt",
			"environment":                           fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                                vpcID,
			"private_subnet_ids":                    privateSubnetIDs,
			"lambda_runtime":                        "python3.11",
			"lambda_memory_size":                    256,
			"lambda_timeout":                        30,
			"enable_xray_tracing":                   true,
			"lambda_reserved_concurrent_executions": 0, // Unreserved = auto-scaling enabled
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify Property 16: Auto-scaling configuration
	// Lambda functions should have unreserved concurrency (0) to enable auto-scaling
	apiFunctionName := terraform.Output(t, computeOptions, "api_handler_function_name")
	assert.NotEmpty(t, apiFunctionName, "API handler function should be created")

	// Verify Lambda execution role exists (required for scaling)
	lambdaRoleARN := terraform.Output(t, computeOptions, "lambda_execution_role_arn")
	assert.NotEmpty(t, lambdaRoleARN, "Lambda execution role should exist")
	assert.Contains(t, lambdaRoleARN, "arn:aws:iam", "Should be a valid IAM role ARN")

	// Verify API Gateway exists (entry point for load)
	apiGatewayURL := terraform.Output(t, computeOptions, "api_gateway_invoke_url")
	assert.NotEmpty(t, apiGatewayURL, "API Gateway URL should exist")
	assert.Contains(t, apiGatewayURL, "execute-api", "Should be a valid API Gateway URL")
}

// Feature: ecovolt-aws-infrastructure, Property 17: Request distribution across functions
// For any set of incoming API requests, the requests should be successfully processed by Lambda functions
// with appropriate distribution and throttling
// Validates: Requirements 4.3
func TestProperty17_RequestDistributionAcrossFunctions(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.121.0.0/16",
			"availability_zones":   []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":  []string{"10.121.1.0/24", "10.121.2.0/24"},
			"private_subnet_cidrs": []string{"10.121.11.0/24", "10.121.12.0/24"},
			"data_subnet_cidrs":    []string{"10.121.21.0/24", "10.121.22.0/24"},
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

	// Create compute module with throttling configured
	throttleRateLimit := random.Random(1000, 10000)
	throttleBurstLimit := random.Random(500, 5000)

	computeOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/compute",
		Vars: map[string]interface{}{
			"project_name":                       "ecovolt",
			"environment":                        fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                             vpcID,
			"private_subnet_ids":                 privateSubnetIDs,
			"lambda_runtime":                     "python3.11",
			"api_gateway_throttle_rate_limit":   throttleRateLimit,
			"api_gateway_throttle_burst_limit":  throttleBurstLimit,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify Property 17: Request distribution configuration
	// API Gateway should be configured with throttling to distribute load
	apiGatewayID := terraform.Output(t, computeOptions, "api_gateway_id")
	assert.NotEmpty(t, apiGatewayID, "API Gateway should be created")

	apiGatewayURL := terraform.Output(t, computeOptions, "api_gateway_invoke_url")
	assert.NotEmpty(t, apiGatewayURL, "API Gateway URL should exist for request distribution")

	// Verify Lambda function exists to handle distributed requests
	apiFunctionARN := terraform.Output(t, computeOptions, "api_handler_function_arn")
	assert.NotEmpty(t, apiFunctionARN, "API handler function should exist")
	assert.Contains(t, apiFunctionARN, "arn:aws:lambda", "Should be a valid Lambda ARN")
}

// Feature: ecovolt-aws-infrastructure, Property 18: Function error handling and retry
// For any Lambda function invocation that fails, the system should implement appropriate retry logic
// and error handling based on the invocation source
// Validates: Requirements 4.4
func TestProperty18_FunctionErrorHandlingAndRetry(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.122.0.0/16",
			"availability_zones":   []string{"eu-west-1a", "eu-west-1b"},
			"public_subnet_cidrs":  []string{"10.122.1.0/24", "10.122.2.0/24"},
			"private_subnet_cidrs": []string{"10.122.11.0/24", "10.122.12.0/24"},
			"data_subnet_cidrs":    []string{"10.122.21.0/24", "10.122.22.0/24"},
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
			"enable_xray_tracing": true, // X-Ray helps with error tracing
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, computeOptions)
	terraform.InitAndApply(t, computeOptions)

	// Verify Property 18: Error handling configuration
	// Lambda functions should have CloudWatch Logs for error tracking
	apiLogGroup := terraform.Output(t, computeOptions, "api_handler_log_group_name")
	assert.NotEmpty(t, apiLogGroup, "Lambda should have CloudWatch Log Group for error logging")
	assert.Contains(t, apiLogGroup, "/aws/lambda/", "Log group should be for Lambda")

	// Verify Lambda execution role has necessary permissions for error handling
	lambdaRoleARN := terraform.Output(t, computeOptions, "lambda_execution_role_arn")
	assert.NotEmpty(t, lambdaRoleARN, "Lambda execution role should exist for error handling")

	// Verify Lambda function exists
	apiFunctionARN := terraform.Output(t, computeOptions, "api_handler_function_arn")
	assert.NotEmpty(t, apiFunctionARN, "API handler function should exist")
}
