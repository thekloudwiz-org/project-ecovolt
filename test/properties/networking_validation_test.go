package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Quick validation test - runs once to verify module works
func TestNetworkingModuleValidation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	vpcCIDR := "10.100.0.0/16"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"project_name":         "ecovolt",
			"vpc_cidr":             vpcCIDR,
			"availability_zones":   []string{"eu-central-1a", "eu-central-1b"},
			"public_subnet_cidrs":  []string{"10.100.1.0/24", "10.100.2.0/24"},
			"private_subnet_cidrs": []string{"10.100.11.0/24", "10.100.12.0/24"},
			"data_subnet_cidrs":    []string{"10.100.21.0/24", "10.100.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "Validation",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify basic outputs
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.Equal(t, 2, len(publicSubnetIDs), "Should have 2 public subnets")

	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Equal(t, 2, len(privateSubnetIDs), "Should have 2 private subnets")

	dataSubnetIDs := terraform.OutputList(t, terraformOptions, "data_subnet_ids")
	assert.Equal(t, 2, len(dataSubnetIDs), "Should have 2 data subnets")

	natGatewayIPs := terraform.OutputList(t, terraformOptions, "nat_gateway_ips")
	assert.Equal(t, 2, len(natGatewayIPs), "Should have 2 NAT Gateways")

	// Verify SSM parameters
	ssmVPCParam := terraform.Output(t, terraformOptions, "ssm_vpc_id_parameter")
	assert.Contains(t, ssmVPCParam, "/networking/vpc_id", "SSM parameter should contain correct path")

	t.Logf("✅ Validation test passed!")
	t.Logf("   VPC ID: %s", vpcID)
	t.Logf("   Public Subnets: %d", len(publicSubnetIDs))
	t.Logf("   Private Subnets: %d", len(privateSubnetIDs))
	t.Logf("   Data Subnets: %d", len(dataSubnetIDs))
	t.Logf("   NAT Gateways: %d", len(natGatewayIPs))
}
