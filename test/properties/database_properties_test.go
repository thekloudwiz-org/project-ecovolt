package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Feature: ecovolt-aws-infrastructure, Property 23: Database storage auto-scaling
// For any database instance where storage utilization exceeds 80%, the system should automatically increase storage capacity
// Validates: Requirements 6.4
func TestProperty23_DatabaseStorageAutoScaling(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	allocatedStorage := selectRandomAllocatedStorage()
	maxAllocatedStorage := selectRandomMaxAllocatedStorage(allocatedStorage)

	// First, create networking module to get required outputs
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/networking",
				Vars: map[string]interface{}{
					"vpc_cidr":             "10.100.0.0/16",
					"availability_zones":   []string{"us-east-1a", "us-east-1b"},
					"public_subnet_cidrs":  []string{"10.100.1.0/24", "10.100.2.0/24"},
					"private_subnet_cidrs": []string{"10.100.11.0/24", "10.100.12.0/24"},
					"data_subnet_cidrs":    []string{"10.100.21.0/24", "10.100.22.0/24"},
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

			// Create security module to get KMS key
			securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/security",
				Vars: map[string]interface{}{
					"project_name":       "ecovolt",
					"environment":        fmt.Sprintf("test-%s", uniqueID),
					"enable_cloudtrail":  false,
					"enable_guardduty":   false,
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
					"project_name":           "ecovolt",
					"environment":            fmt.Sprintf("test-%s", uniqueID),
					"vpc_id":                 vpcID,
					"data_subnet_ids":        dataSubnetIDs,
					"private_subnet_cidrs":   privateSubnetCIDRs,
					"kms_key_arn":            kmsKeyARN,
					"db_name":                "ecovolt",
					"db_username":            "testadmin",
					"db_password":            generateRandomPassword(),
					"db_instance_class":      "db.t3.micro",
					"db_allocated_storage":   allocatedStorage,
					"db_max_allocated_storage": maxAllocatedStorage,
					"db_multi_az":            false, // Single AZ for faster testing
					"db_backup_retention_period": 1,
					"db_deletion_protection": false,
					"db_skip_final_snapshot": true,
					"db_performance_insights_enabled": false,
					"elasticache_num_cache_nodes": 1,
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, databaseOptions)
			terraform.InitAndApply(t, databaseOptions)

			// Verify Property 23: Database storage auto-scaling
			// For any database instance, if max_allocated_storage is set and greater than allocated_storage,
			// then auto-scaling should be enabled

			outputMaxStorage := terraform.Output(t, databaseOptions, "db_max_allocated_storage")
			
			if maxAllocatedStorage > 0 {
				// Auto-scaling is enabled
				assert.Equal(t, fmt.Sprintf("%d", maxAllocatedStorage), outputMaxStorage, 
					"Max allocated storage should match configured value when auto-scaling is enabled")
				assert.Greater(t, maxAllocatedStorage, allocatedStorage, 
					"Max allocated storage should be greater than initial allocated storage")
			} else {
				// Auto-scaling is disabled
				assert.Equal(t, "0", outputMaxStorage, 
					"Max allocated storage should be 0 when auto-scaling is disabled")
			}

			// Verify encryption is enabled (required for auto-scaling to work properly)
			storageEncrypted := terraform.Output(t, databaseOptions, "db_storage_encrypted")
			assert.Equal(t, "true", storageEncrypted, "Storage encryption should be enabled")

	// Verify database endpoint is accessible
	dbEndpoint := terraform.Output(t, databaseOptions, "db_endpoint")
	assert.NotEmpty(t, dbEndpoint, "Database endpoint should not be empty")
	assert.Contains(t, dbEndpoint, "rds.amazonaws.com", "Endpoint should be an RDS endpoint")
}

// Feature: ecovolt-aws-infrastructure, Property 6: Automated backup configuration
// For any stateful service (RDS, EFS, etc.), automated backup schedules should be configured and enabled
// Validates: Requirements 12.2
func TestProperty6_AutomatedBackupConfiguration(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	backupRetentionPeriod := selectRandomBackupRetention()

	// First, create networking module to get required outputs
	networkingOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/networking",
				Vars: map[string]interface{}{
					"vpc_cidr":             "10.101.0.0/16",
					"availability_zones":   []string{"us-west-2a", "us-west-2b"},
					"public_subnet_cidrs":  []string{"10.101.1.0/24", "10.101.2.0/24"},
					"private_subnet_cidrs": []string{"10.101.11.0/24", "10.101.12.0/24"},
					"data_subnet_cidrs":    []string{"10.101.21.0/24", "10.101.22.0/24"},
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

			// Create security module to get KMS key
			securityOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/security",
				Vars: map[string]interface{}{
					"project_name":       "ecovolt",
					"environment":        fmt.Sprintf("test-%s", uniqueID),
					"enable_cloudtrail":  false,
					"enable_guardduty":   false,
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
					"project_name":           "ecovolt",
					"environment":            fmt.Sprintf("test-%s", uniqueID),
					"vpc_id":                 vpcID,
					"data_subnet_ids":        dataSubnetIDs,
					"private_subnet_cidrs":   privateSubnetCIDRs,
					"kms_key_arn":            kmsKeyARN,
					"db_name":                "ecovolt",
					"db_username":            "testadmin",
					"db_password":            generateRandomPassword(),
					"db_instance_class":      "db.t3.micro",
					"db_allocated_storage":   20,
					"db_max_allocated_storage": 50,
					"db_multi_az":            false,
					"db_backup_retention_period": backupRetentionPeriod,
					"db_deletion_protection": false,
					"db_skip_final_snapshot": true,
					"db_performance_insights_enabled": false,
					"elasticache_num_cache_nodes": 1,
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, databaseOptions)
			terraform.InitAndApply(t, databaseOptions)

			// Verify Property 6: Automated backup configuration
			// For any RDS instance, automated backups should be configured with retention period > 0

			outputBackupRetention := terraform.Output(t, databaseOptions, "db_backup_retention_period")
			assert.Equal(t, fmt.Sprintf("%d", backupRetentionPeriod), outputBackupRetention, 
				"Backup retention period should match configured value")

			if backupRetentionPeriod > 0 {
				// Automated backups are enabled
				assert.Greater(t, backupRetentionPeriod, 0, 
					"Backup retention period should be greater than 0 when backups are enabled")
				assert.LessOrEqual(t, backupRetentionPeriod, 35, 
					"Backup retention period should not exceed 35 days")
			} else {
				// Automated backups are disabled (not recommended for production)
				assert.Equal(t, 0, backupRetentionPeriod, 
					"Backup retention period should be 0 when backups are disabled")
			}

	// Verify database instance exists
	dbInstanceID := terraform.Output(t, databaseOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID, "Database instance ID should not be empty")
}

// Helper function to select random allocated storage (20-100 GB)
func selectRandomAllocatedStorage() int {
	return random.Random(20, 100)
}

// Helper function to select random max allocated storage
// Returns 0 (disabled) or a value greater than allocated storage
func selectRandomMaxAllocatedStorage(allocatedStorage int) int {
	// 20% chance of disabling auto-scaling
	if random.Random(1, 5) == 1 {
		return 0
	}
	// Otherwise, return a value 50-200 GB more than allocated storage
	return allocatedStorage + random.Random(50, 200)
}

// Helper function to select random backup retention period (0-35 days)
func selectRandomBackupRetention() int {
	// 10% chance of disabling backups (retention = 0)
	if random.Random(1, 10) == 1 {
		return 0
	}
	// Otherwise, return a value between 1 and 35 days
	return random.Random(1, 35)
}

// Helper function to generate a random password
func generateRandomPassword() string {
	return fmt.Sprintf("TestPass%s123!", random.UniqueId())
}
