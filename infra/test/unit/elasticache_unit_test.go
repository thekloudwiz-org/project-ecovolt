package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestElastiCacheCreation tests that ElastiCache resources are created when enabled
func TestElastiCacheCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": true,
			"redis_node_type":    "cache.t3.micro",
			"redis_num_cache_nodes": 2,
			"redis_multi_az":     true,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Verify ElastiCache resources will be created
	expectedResources := []string{
		"aws_elasticache_subnet_group.redis[0]",
		"aws_security_group.redis[0]",
		"aws_elasticache_parameter_group.redis[0]",
		"aws_elasticache_replication_group.redis[0]",
	}

	for _, resource := range expectedResources {
		assert.Contains(t, planStruct.ResourceChangesMap, resource, "Resource %s should be created", resource)
	}
}

// TestElastiCacheDisabled tests that ElastiCache resources are not created when disabled
func TestElastiCacheDisabled(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": false,
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Verify ElastiCache resources are NOT created
	_, hasSubnetGroup := planStruct.ResourceChangesMap["aws_elasticache_subnet_group.redis[0]"]
	assert.False(t, hasSubnetGroup, "ElastiCache subnet group should not be created when disabled")
	
	_, hasReplicationGroup := planStruct.ResourceChangesMap["aws_elasticache_replication_group.redis[0]"]
	assert.False(t, hasReplicationGroup, "ElastiCache replication group should not be created when disabled")
}

// TestElastiCacheMultiAZ tests Multi-AZ configuration
func TestElastiCacheMultiAZ(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name      string
		multiAZ   bool
		numNodes  int
	}{
		{"Multi-AZ Enabled", true, 2},
		{"Single-AZ", false, 1},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/database",
				Vars: map[string]interface{}{
					"project_name":       "test-ecovolt",
					"environment":        "test",
					"vpc_id":             "vpc-12345678",
					"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
					"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
					"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"db_name":            "testdb",
					"db_username":        "testuser",
					"db_password":        "testpassword123!",
					"enable_elasticache": true,
					"redis_multi_az":     tc.multiAZ,
					"redis_num_cache_nodes": tc.numNodes,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			replicationGroup := planStruct.ResourceChangesMap["aws_elasticache_replication_group.redis[0]"]
			plannedValues := replicationGroup.Change.After.(map[string]interface{})
			
			assert.Equal(t, tc.multiAZ, plannedValues["automatic_failover_enabled"])
			assert.Equal(t, tc.multiAZ, plannedValues["multi_az_enabled"])
			assert.Equal(t, float64(tc.numNodes), plannedValues["num_cache_clusters"])
		})
	}
}

// TestElastiCacheEncryption tests encryption configuration
func TestElastiCacheEncryption(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": true,
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	replicationGroup := planStruct.ResourceChangesMap["aws_elasticache_replication_group.redis[0]"]
	plannedValues := replicationGroup.Change.After.(map[string]interface{})
	
	// Verify encryption at rest and in transit
	assert.Equal(t, true, plannedValues["at_rest_encryption_enabled"])
	assert.Equal(t, true, plannedValues["transit_encryption_enabled"])
}

// TestElastiCacheAuthToken tests AUTH token configuration
func TestElastiCacheAuthToken(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name              string
		authTokenEnabled  bool
		authToken         string
	}{
		{"AUTH Enabled", true, "test-auth-token-123456"},
		{"AUTH Disabled", false, ""},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/database",
				Vars: map[string]interface{}{
					"project_name":       "test-ecovolt",
					"environment":        "test",
					"vpc_id":             "vpc-12345678",
					"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
					"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
					"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"db_name":            "testdb",
					"db_username":        "testuser",
					"db_password":        "testpassword123!",
					"enable_elasticache": true,
					"redis_auth_token_enabled": tc.authTokenEnabled,
					"redis_auth_token":   tc.authToken,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			replicationGroup := planStruct.ResourceChangesMap["aws_elasticache_replication_group.redis[0]"]
			plannedValues := replicationGroup.Change.After.(map[string]interface{})
			
			assert.Equal(t, tc.authTokenEnabled, plannedValues["auth_token_enabled"])
		})
	}
}

// TestElastiCacheCloudWatchAlarms tests that CloudWatch alarms are created
func TestElastiCacheCloudWatchAlarms(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": true,
			"redis_multi_az":     true,
			"alarm_sns_topic_arns": []string{
				"arn:aws:sns:us-east-1:123456789012:test-topic",
			},
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Verify alarms are created
	expectedAlarms := []string{
		"aws_cloudwatch_metric_alarm.redis_cpu[0]",
		"aws_cloudwatch_metric_alarm.redis_memory[0]",
		"aws_cloudwatch_metric_alarm.redis_evictions[0]",
		"aws_cloudwatch_metric_alarm.redis_replication_lag[0]",
	}

	for _, alarmName := range expectedAlarms {
		assert.Contains(t, planStruct.ResourceChangesMap, alarmName, "Alarm %s should be created", alarmName)
	}
}

// TestElastiCacheSSMParameters tests that SSM parameters are created
func TestElastiCacheSSMParameters(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": true,
			"redis_multi_az":     true,
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Verify SSM parameters are created
	expectedParameters := []string{
		"aws_ssm_parameter.redis_endpoint[0]",
		"aws_ssm_parameter.redis_port[0]",
		"aws_ssm_parameter.redis_reader_endpoint[0]",
	}

	for _, paramName := range expectedParameters {
		assert.Contains(t, planStruct.ResourceChangesMap, paramName, "SSM parameter %s should be created", paramName)
	}
}

// TestElastiCacheParameterGroup tests parameter group configuration
func TestElastiCacheParameterGroup(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/database",
		Vars: map[string]interface{}{
			"project_name":       "test-ecovolt",
			"environment":        "test",
			"vpc_id":             "vpc-12345678",
			"data_subnet_ids":    []string{"subnet-12345678", "subnet-87654321"},
			"private_subnet_cidrs": []string{"10.0.11.0/24", "10.0.12.0/24"},
			"kms_key_arn":        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"db_name":            "testdb",
			"db_username":        "testuser",
			"db_password":        "testpassword123!",
			"enable_elasticache": true,
			"redis_family":       "redis7",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	parameterGroup := planStruct.ResourceChangesMap["aws_elasticache_parameter_group.redis[0]"]
	plannedValues := parameterGroup.Change.After.(map[string]interface{})
	
	assert.Equal(t, "redis7", plannedValues["family"])
	
	// Verify parameters are set
	parameters := plannedValues["parameter"].([]interface{})
	assert.GreaterOrEqual(t, len(parameters), 1, "Should have at least one parameter")
}
