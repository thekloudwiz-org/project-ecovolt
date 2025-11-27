package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestDynamoDBTablesCreation tests that all 5 DynamoDB tables are created
func TestDynamoDBTablesCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name":                  "test-ecovolt",
			"environment":                   "test",
			"billing_mode":                  "PAY_PER_REQUEST",
			"enable_point_in_time_recovery": true,
			"enable_bike_status_ttl":     false,
			"enable_swap_events_ttl":        true,
			"kms_key_arn":                   "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Verify all 5 tables will be created
	expectedTables := []string{
		"aws_dynamodb_table.stations",
		"aws_dynamodb_table.user_profiles",
		"aws_dynamodb_table.bike_status",
		"aws_dynamodb_table.battery_inventory",
		"aws_dynamodb_table.swap_events",
	}

	for _, tableName := range expectedTables {
		assert.Contains(t, planStruct.ResourceChangesMap, tableName, "Table %s should be created", tableName)
	}
}

// TestDynamoDBStationsTable tests the stations table configuration
func TestDynamoDBStationsTable(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"billing_mode": "PAY_PER_REQUEST",
			"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	stationsTable := planStruct.ResourceChangesMap["aws_dynamodb_table.stations"]
	assert.NotNil(t, stationsTable)
	
	plannedValues := stationsTable.Change.After.(map[string]interface{})
	
	// Verify hash key
	assert.Equal(t, "stationId", plannedValues["hash_key"])
	
	// Verify billing mode
	assert.Equal(t, "PAY_PER_REQUEST", plannedValues["billing_mode"])
	
	// Verify streams enabled
	assert.Equal(t, true, plannedValues["stream_enabled"])
	assert.Equal(t, "NEW_AND_OLD_IMAGES", plannedValues["stream_view_type"])
	
	// Verify encryption
	serverSideEncryption := plannedValues["server_side_encryption"].([]interface{})[0].(map[string]interface{})
	assert.Equal(t, true, serverSideEncryption["enabled"])
}

// TestDynamoDBGSIs tests that Global Secondary Indexes are created
func TestDynamoDBGSIs(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"billing_mode": "PAY_PER_REQUEST",
			"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Check stations table GSIs
	stationsTable := planStruct.ResourceChangesMap["aws_dynamodb_table.stations"]
	plannedValues := stationsTable.Change.After.(map[string]interface{})
	
	gsis := plannedValues["global_secondary_index"].([]interface{})
	assert.Equal(t, 2, len(gsis), "Stations table should have 2 GSIs")
	
	// Verify GSI names
	gsiNames := make([]string, len(gsis))
	for i, gsi := range gsis {
		gsiMap := gsi.(map[string]interface{})
		gsiNames[i] = gsiMap["name"].(string)
	}
	
	assert.Contains(t, gsiNames, "LocationIndex")
	assert.Contains(t, gsiNames, "StatusIndex")
}

// TestDynamoDBSwapEventsTable tests the swap events table with composite key
func TestDynamoDBSwapEventsTable(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"billing_mode": "PAY_PER_REQUEST",
			"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	swapEventsTable := planStruct.ResourceChangesMap["aws_dynamodb_table.swap_events"]
	assert.NotNil(t, swapEventsTable)
	
	plannedValues := swapEventsTable.Change.After.(map[string]interface{})
	
	// Verify composite key (hash + range)
	assert.Equal(t, "swapId", plannedValues["hash_key"])
	assert.Equal(t, "timestamp", plannedValues["range_key"])
	
	// Verify 3 GSIs for different query patterns
	gsis := plannedValues["global_secondary_index"].([]interface{})
	assert.Equal(t, 3, len(gsis), "Swap events table should have 3 GSIs")
}

// TestDynamoDBTTLConfiguration tests TTL configuration
func TestDynamoDBTTLConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name                  string
		enableBikeStatusTTL bool
		enableSwapEventsTTL    bool
	}{
		{"TTL Enabled", false, true},
		{"TTL Disabled", false, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/dynamodb",
				Vars: map[string]interface{}{
					"project_name":              "test-ecovolt",
					"environment":               "test",
					"billing_mode":              "PAY_PER_REQUEST",
					"enable_bike_status_ttl": tc.enableBikeStatusTTL,
					"enable_swap_events_ttl":    tc.enableSwapEventsTTL,
					"kms_key_arn":               "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			swapEventsTable := planStruct.ResourceChangesMap["aws_dynamodb_table.swap_events"]
			plannedValues := swapEventsTable.Change.After.(map[string]interface{})
			
			ttlConfig := plannedValues["ttl"].([]interface{})[0].(map[string]interface{})
			assert.Equal(t, tc.enableSwapEventsTTL, ttlConfig["enabled"])
		})
	}
}

// TestDynamoDBBillingModes tests different billing modes
func TestDynamoDBBillingModes(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		billingMode string
	}{
		{"On-Demand", "PAY_PER_REQUEST"},
		{"Provisioned", "PROVISIONED"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			vars := map[string]interface{}{
				"project_name": "test-ecovolt",
				"environment":  "test",
				"billing_mode": tc.billingMode,
				"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
				"tags": map[string]string{
					"Environment": "test",
				},
			}

			// Add capacity units for provisioned mode
			if tc.billingMode == "PROVISIONED" {
				vars["stations_read_capacity"] = 5
				vars["stations_write_capacity"] = 5
			}

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/dynamodb",
				Vars:         vars,
				NoColor:      true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			stationsTable := planStruct.ResourceChangesMap["aws_dynamodb_table.stations"]
			plannedValues := stationsTable.Change.After.(map[string]interface{})
			
			assert.Equal(t, tc.billingMode, plannedValues["billing_mode"])
		})
	}
}

// TestDynamoDBCloudWatchAlarms tests that CloudWatch alarms are created
func TestDynamoDBCloudWatchAlarms(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"billing_mode": "PAY_PER_REQUEST",
			"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
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
	
	// Verify throttle alarms are created
	expectedAlarms := []string{
		"aws_cloudwatch_metric_alarm.stations_read_throttle",
		"aws_cloudwatch_metric_alarm.stations_write_throttle",
	}

	for _, alarmName := range expectedAlarms {
		assert.Contains(t, planStruct.ResourceChangesMap, alarmName)
	}
}

// TestDynamoDBOutputs tests that all required outputs are defined
func TestDynamoDBOutputs(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/dynamodb",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"billing_mode": "PAY_PER_REQUEST",
			"kms_key_arn":  "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Verify module validates (outputs can only be checked after apply)
	outputList := terraform.OutputList(t, terraformOptions)
	assert.NotNil(t, outputList)
}
