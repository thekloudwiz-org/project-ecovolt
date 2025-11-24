package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test VPC creation with valid CIDR blocks
func TestVPCCreationWithValidCIDR(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	vpcCIDR := "10.0.0.0/16"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             vpcCIDR,
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"data_subnet_cidrs":    []string{"10.0.21.0/24", "10.0.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "VPCCreation",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify VPC was created
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	// Verify VPC CIDR matches input
	outputVPCCIDR := terraform.Output(t, terraformOptions, "vpc_cidr")
	assert.Equal(t, vpcCIDR, outputVPCCIDR, "VPC CIDR should match input")
}

// Test subnet creation across specified AZs
func TestSubnetCreationAcrossAZs(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	azs := []string{"us-west-2a", "us-west-2b", "us-west-2c"}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.1.0.0/16",
			"availability_zones":   azs,
			"public_subnet_cidrs":  []string{"10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"},
			"private_subnet_cidrs": []string{"10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"},
			"data_subnet_cidrs":    []string{"10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "SubnetCreation",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify correct number of subnets created
	publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	dataSubnets := terraform.OutputList(t, terraformOptions, "data_subnet_ids")

	assert.Equal(t, len(azs), len(publicSubnets), "Should create one public subnet per AZ")
	assert.Equal(t, len(azs), len(privateSubnets), "Should create one private subnet per AZ")
	assert.Equal(t, len(azs), len(dataSubnets), "Should create one data subnet per AZ")

	// Verify subnet CIDRs
	publicCIDRs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	privateCIDRs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	dataCIDRs := terraform.OutputList(t, terraformOptions, "data_subnet_cidrs")

	assert.Equal(t, []string{"10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"}, publicCIDRs)
	assert.Equal(t, []string{"10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"}, privateCIDRs)
	assert.Equal(t, []string{"10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"}, dataCIDRs)
}

// Test route table associations
func TestRouteTableAssociations(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	azCount := 3

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.2.0.0/16",
			"availability_zones":   []string{"eu-central-1a", "eu-central-1b", "eu-central-1c"},
			"public_subnet_cidrs":  []string{"10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"},
			"private_subnet_cidrs": []string{"10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"},
			"data_subnet_cidrs":    []string{"10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "RouteTableAssociations",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify public route table exists (single shared route table)
	publicRouteTableID := terraform.Output(t, terraformOptions, "public_route_table_id")
	assert.NotEmpty(t, publicRouteTableID, "Public route table should exist")

	// Verify private route tables (one per AZ for NAT Gateway routing)
	privateRouteTableIDs := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
	assert.Equal(t, azCount, len(privateRouteTableIDs), "Should have one private route table per AZ")

	// Verify data route tables (one per AZ)
	dataRouteTableIDs := terraform.OutputList(t, terraformOptions, "data_route_table_ids")
	assert.Equal(t, azCount, len(dataRouteTableIDs), "Should have one data route table per AZ")

	// Verify all route table IDs are unique
	allRouteTables := append([]string{publicRouteTableID}, privateRouteTableIDs...)
	allRouteTables = append(allRouteTables, dataRouteTableIDs...)
	uniqueRouteTables := make(map[string]bool)
	for _, rt := range allRouteTables {
		assert.False(t, uniqueRouteTables[rt], "Route table IDs should be unique")
		uniqueRouteTables[rt] = true
	}
}

// Test NAT Gateway configuration
func TestNATGatewayConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	azCount := 2

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.3.0.0/16",
			"availability_zones":   []string{"ap-southeast-1a", "ap-southeast-1b"},
			"public_subnet_cidrs":  []string{"10.3.1.0/24", "10.3.2.0/24"},
			"private_subnet_cidrs": []string{"10.3.11.0/24", "10.3.12.0/24"},
			"data_subnet_cidrs":    []string{"10.3.21.0/24", "10.3.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "NATGateway",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify NAT Gateways created (one per AZ)
	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Equal(t, azCount, len(natGatewayIDs), "Should have one NAT Gateway per AZ")

	// Verify Elastic IPs allocated for NAT Gateways
	natGatewayIPs := terraform.OutputList(t, terraformOptions, "nat_gateway_ips")
	assert.Equal(t, azCount, len(natGatewayIPs), "Should have one Elastic IP per NAT Gateway")

	// Verify all NAT Gateway IDs are unique
	uniqueNATs := make(map[string]bool)
	for _, nat := range natGatewayIDs {
		assert.False(t, uniqueNATs[nat], "NAT Gateway IDs should be unique")
		uniqueNATs[nat] = true
	}

	// Verify all Elastic IPs are unique
	uniqueIPs := make(map[string]bool)
	for _, ip := range natGatewayIPs {
		assert.NotEmpty(t, ip, "Elastic IP should not be empty")
		assert.False(t, uniqueIPs[ip], "Elastic IPs should be unique")
		uniqueIPs[ip] = true
	}
}

// Test NAT Gateway disabled configuration
func TestNATGatewayDisabled(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.4.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.4.1.0/24", "10.4.2.0/24"},
			"private_subnet_cidrs": []string{"10.4.11.0/24", "10.4.12.0/24"},
			"data_subnet_cidrs":    []string{"10.4.21.0/24", "10.4.22.0/24"},
			"enable_nat_gateway":   false, // Disabled
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "NATGatewayDisabled",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify no NAT Gateways created
	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Empty(t, natGatewayIDs, "Should have no NAT Gateways when disabled")

	// Verify no Elastic IPs allocated
	natGatewayIPs := terraform.OutputList(t, terraformOptions, "nat_gateway_ips")
	assert.Empty(t, natGatewayIPs, "Should have no Elastic IPs when NAT Gateway disabled")
}

// Test VPC Flow Logs configuration
func TestVPCFlowLogsConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.5.0.0/16",
			"availability_zones":   []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":  []string{"10.5.1.0/24", "10.5.2.0/24"},
			"private_subnet_cidrs": []string{"10.5.11.0/24", "10.5.12.0/24"},
			"data_subnet_cidrs":    []string{"10.5.21.0/24", "10.5.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "FlowLogs",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify VPC Flow Logs enabled
	flowLogID := terraform.Output(t, terraformOptions, "flow_log_id")
	assert.NotEmpty(t, flowLogID, "VPC Flow Log should be created")

	// Verify CloudWatch Log Group created
	flowLogGroupName := terraform.Output(t, terraformOptions, "flow_log_group_name")
	assert.NotEmpty(t, flowLogGroupName, "Flow Log CloudWatch Log Group should be created")
	assert.Contains(t, flowLogGroupName, "flow-logs", "Log group name should contain 'flow-logs'")
	assert.Contains(t, flowLogGroupName, uniqueID, "Log group name should contain environment identifier")
}

// Test Internet Gateway configuration
func TestInternetGatewayConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.6.0.0/16",
			"availability_zones":   []string{"eu-west-1a", "eu-west-1b"},
			"public_subnet_cidrs":  []string{"10.6.1.0/24", "10.6.2.0/24"},
			"private_subnet_cidrs": []string{"10.6.11.0/24", "10.6.12.0/24"},
			"data_subnet_cidrs":    []string{"10.6.21.0/24", "10.6.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "InternetGateway",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Internet Gateway created
	igwID := terraform.Output(t, terraformOptions, "internet_gateway_id")
	assert.NotEmpty(t, igwID, "Internet Gateway should be created")
}

// Test VPN Gateway configuration (optional)
func TestVPNGatewayConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.7.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.7.1.0/24", "10.7.2.0/24"},
			"private_subnet_cidrs": []string{"10.7.11.0/24", "10.7.12.0/24"},
			"data_subnet_cidrs":    []string{"10.7.21.0/24", "10.7.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   true, // Enabled
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "VPNGateway",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify VPN Gateway created
	vpnGatewayID := terraform.Output(t, terraformOptions, "vpn_gateway_id")
	assert.NotEmpty(t, vpnGatewayID, "VPN Gateway should be created when enabled")
}

// Test minimum AZ configuration (2 AZs)
func TestMinimumAZConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	azCount := 2

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.8.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.8.1.0/24", "10.8.2.0/24"},
			"private_subnet_cidrs": []string{"10.8.11.0/24", "10.8.12.0/24"},
			"data_subnet_cidrs":    []string{"10.8.21.0/24", "10.8.22.0/24"},
			"enable_nat_gateway":   true,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
			"tags": map[string]string{
				"Test": "MinimumAZ",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify resources created for minimum AZ count
	publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	dataSubnets := terraform.OutputList(t, terraformOptions, "data_subnet_ids")
	natGateways := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")

	assert.Equal(t, azCount, len(publicSubnets), "Should create subnets for minimum AZ count")
	assert.Equal(t, azCount, len(privateSubnets), "Should create subnets for minimum AZ count")
	assert.Equal(t, azCount, len(dataSubnets), "Should create subnets for minimum AZ count")
	assert.Equal(t, azCount, len(natGateways), "Should create NAT Gateways for minimum AZ count")
}
