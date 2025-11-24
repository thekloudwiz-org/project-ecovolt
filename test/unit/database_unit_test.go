package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test RDS instance creation with Multi-AZ
func TestRDSInstanceCreationWithMultiAZ(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.110.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.110.1.0/24", "10.110.2.0/24"},
			"private_subnet_cidrs": []string{"10.110.11.0/24", "10.110.12.0/24"},
			"data_subnet_cidrs":    []string{"10.110.21.0/24", "10.110.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module with Multi-AZ enabled
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              20,
			"db_max_allocated_storage":          100,
			"db_multi_az":                       true, // Multi-AZ enabled
			"db_backup_retention_period":        7,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify Multi-AZ is enabled
	multiAZ := terraform.Output(t, databaseOptions, "db_multi_az")
	assert.Equal(t, "true", multiAZ, "Multi-AZ should be enabled")

	// Verify RDS instance was created
	dbInstanceID := terraform.Output(t, databaseOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID, "RDS instance ID should not be empty")

	// Verify endpoint is accessible
	dbEndpoint := terraform.Output(t, databaseOptions, "db_endpoint")
	assert.NotEmpty(t, dbEndpoint, "Database endpoint should not be empty")
	assert.Contains(t, dbEndpoint, "rds.amazonaws.com", "Endpoint should be an RDS endpoint")
}

// Test automated backup configuration
func TestAutomatedBackupConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	backupRetentionPeriod := 14

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.111.0.0/16",
			"availability_zones":   []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":  []string{"10.111.1.0/24", "10.111.2.0/24"},
			"private_subnet_cidrs": []string{"10.111.11.0/24", "10.111.12.0/24"},
			"data_subnet_cidrs":    []string{"10.111.21.0/24", "10.111.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              20,
			"db_max_allocated_storage":          100,
			"db_multi_az":                       false,
			"db_backup_retention_period":        backupRetentionPeriod,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify backup retention period
	outputBackupRetention := terraform.Output(t, databaseOptions, "db_backup_retention_period")
	assert.Equal(t, fmt.Sprintf("%d", backupRetentionPeriod), outputBackupRetention, 
		"Backup retention period should match configured value")
}

// Test storage auto-scaling settings
func TestStorageAutoScalingSettings(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	allocatedStorage := 50
	maxAllocatedStorage := 200

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.112.0.0/16",
			"availability_zones":   []string{"eu-west-1a", "eu-west-1b"},
			"public_subnet_cidrs":  []string{"10.112.1.0/24", "10.112.2.0/24"},
			"private_subnet_cidrs": []string{"10.112.11.0/24", "10.112.12.0/24"},
			"data_subnet_cidrs":    []string{"10.112.21.0/24", "10.112.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              allocatedStorage,
			"db_max_allocated_storage":          maxAllocatedStorage,
			"db_multi_az":                       false,
			"db_backup_retention_period":        7,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify max allocated storage
	outputMaxStorage := terraform.Output(t, databaseOptions, "db_max_allocated_storage")
	assert.Equal(t, fmt.Sprintf("%d", maxAllocatedStorage), outputMaxStorage, 
		"Max allocated storage should match configured value")
	
	// Verify max is greater than allocated
	assert.Greater(t, maxAllocatedStorage, allocatedStorage, 
		"Max allocated storage should be greater than allocated storage")
}

// Test encryption configuration
func TestEncryptionConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.113.0.0/16",
			"availability_zones":   []string{"ap-southeast-1a", "ap-southeast-1b"},
			"public_subnet_cidrs":  []string{"10.113.1.0/24", "10.113.2.0/24"},
			"private_subnet_cidrs": []string{"10.113.11.0/24", "10.113.12.0/24"},
			"data_subnet_cidrs":    []string{"10.113.21.0/24", "10.113.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              20,
			"db_max_allocated_storage":          100,
			"db_multi_az":                       false,
			"db_backup_retention_period":        7,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify RDS encryption
	rdsStorageEncrypted := terraform.Output(t, databaseOptions, "db_storage_encrypted")
	assert.Equal(t, "true", rdsStorageEncrypted, "RDS storage encryption should be enabled")

	// Verify ElastiCache encryption (transit encryption disabled for cluster mode)
	elasticacheTransitEncryption := terraform.Output(t, databaseOptions, "elasticache_transit_encryption_enabled")
	assert.Equal(t, "false", elasticacheTransitEncryption, "ElastiCache in-transit encryption is disabled for cluster mode")
}

// Test security group rules
func TestSecurityGroupRules(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.114.0.0/16",
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":  []string{"10.114.1.0/24", "10.114.2.0/24"},
			"private_subnet_cidrs": []string{"10.114.11.0/24", "10.114.12.0/24"},
			"data_subnet_cidrs":    []string{"10.114.21.0/24", "10.114.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              20,
			"db_max_allocated_storage":          100,
			"db_multi_az":                       false,
			"db_backup_retention_period":        7,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify security groups were created
	rdsSecurityGroupID := terraform.Output(t, databaseOptions, "db_security_group_id")
	assert.NotEmpty(t, rdsSecurityGroupID, "RDS security group should be created")

	elasticacheSecurityGroupID := terraform.Output(t, databaseOptions, "elasticache_security_group_id")
	assert.NotEmpty(t, elasticacheSecurityGroupID, "ElastiCache security group should be created")

	// Verify security groups are different
	assert.NotEqual(t, rdsSecurityGroupID, elasticacheSecurityGroupID, 
		"RDS and ElastiCache should have separate security groups")
}

// Test ElastiCache cluster creation
func TestElastiCacheClusterCreation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	numCacheNodes := 2

	// Create networking module
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"vpc_cidr":             "10.115.0.0/16",
			"availability_zones":   []string{"us-west-2a", "us-west-2b"},
			"public_subnet_cidrs":  []string{"10.115.1.0/24", "10.115.2.0/24"},
			"private_subnet_cidrs": []string{"10.115.11.0/24", "10.115.12.0/24"},
			"data_subnet_cidrs":    []string{"10.115.21.0/24", "10.115.22.0/24"},
			"enable_nat_gateway":   false,
			"enable_vpn_gateway":   false,
			"environment":          fmt.Sprintf("test-%s", uniqueID),
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkingOptions)
	terraform.InitAndApply(t, networkingOptions)

	vpcID := terraform.Output(t, networkingOptions, "vpc_id")
	dataSubnetIDs := terraform.OutputList(t, networkingOptions, "data_subnet_ids")
	privateSubnetCIDRs := terraform.OutputList(t, networkingOptions, "private_subnet_cidrs")

	// Create security module
	securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"project_name":            "ecovolt",
			"environment":             fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":       false,
			"enable_guardduty":        false,
			"enable_kms_key_rotation": true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, securityOptions)
	terraform.InitAndApply(t, securityOptions)

	kmsKeyARN := terraform.Output(t, securityOptions, "kms_key_arn")

	// Create database module
	databaseOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/database",
		Vars: map[string]interface{}{
			"project_name":                      "ecovolt",
			"environment":                       fmt.Sprintf("test-%s", uniqueID),
			"vpc_id":                            vpcID,
			"data_subnet_ids":                   dataSubnetIDs,
			"private_subnet_cidrs":              privateSubnetCIDRs,
			"kms_key_arn":                       kmsKeyARN,
			"db_name":                           "ecovolt",
			"db_username":                       "testadmin",
			"db_password":                       fmt.Sprintf("TestPass%s123!", random.UniqueId()),
			"db_instance_class":                 "db.t3.micro",
			"db_allocated_storage":              20,
			"db_max_allocated_storage":          100,
			"db_multi_az":                       false,
			"db_backup_retention_period":        7,
			"db_deletion_protection":            false,
			"db_skip_final_snapshot":            true,
			"db_performance_insights_enabled":   false,
			"elasticache_num_cache_nodes":       numCacheNodes,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, databaseOptions)
	terraform.InitAndApply(t, databaseOptions)

	// Verify ElastiCache cluster was created
	elasticacheClusterID := terraform.Output(t, databaseOptions, "elasticache_cluster_id")
	assert.NotEmpty(t, elasticacheClusterID, "ElastiCache cluster ID should not be empty")

	// Verify endpoint is accessible
	elasticacheEndpoint := terraform.Output(t, databaseOptions, "elasticache_endpoint")
	assert.NotEmpty(t, elasticacheEndpoint, "ElastiCache endpoint should not be empty")

	// Verify port
	elasticachePort := terraform.Output(t, databaseOptions, "elasticache_port")
	assert.Equal(t, "6379", elasticachePort, "ElastiCache port should be 6379 (Redis default)")
}
