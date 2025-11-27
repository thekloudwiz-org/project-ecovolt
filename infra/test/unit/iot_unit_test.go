package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test IoT Thing Type creation for bikes, stations, and batteries
func TestIoTThingTypeCreation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "ThingTypeCreation",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify bike thing type
	bikeThingType := terraform.Output(t, terraformOptions, "bike_thing_type_name")
	assert.NotEmpty(t, bikeThingType, "Bike thing type should be created")
	assert.Contains(t, bikeThingType, "bike", "Bike thing type name should contain 'bike'")

	bikeThingTypeARN := terraform.Output(t, terraformOptions, "bike_thing_type_arn")
	assert.NotEmpty(t, bikeThingTypeARN, "Bike thing type ARN should be available")
	assert.Contains(t, bikeThingTypeARN, "thingtype/", "Should be a thing type ARN")

	// Verify station thing type
	stationThingType := terraform.Output(t, terraformOptions, "station_thing_type_name")
	assert.NotEmpty(t, stationThingType, "Station thing type should be created")
	assert.Contains(t, stationThingType, "station", "Station thing type name should contain 'station'")

	stationThingTypeARN := terraform.Output(t, terraformOptions, "station_thing_type_arn")
	assert.NotEmpty(t, stationThingTypeARN, "Station thing type ARN should be available")
	assert.Contains(t, stationThingTypeARN, "thingtype/", "Should be a thing type ARN")

	// Verify battery thing type
	batteryThingType := terraform.Output(t, terraformOptions, "battery_thing_type_name")
	assert.NotEmpty(t, batteryThingType, "Battery thing type should be created")
	assert.Contains(t, batteryThingType, "battery", "Battery thing type name should contain 'battery'")

	batteryThingTypeARN := terraform.Output(t, terraformOptions, "battery_thing_type_arn")
	assert.NotEmpty(t, batteryThingTypeARN, "Battery thing type ARN should be available")
	assert.Contains(t, batteryThingTypeARN, "thingtype/", "Should be a thing type ARN")

	// Verify all thing types are unique
	assert.NotEqual(t, bikeThingType, stationThingType, "Bike and station thing types should be different")
	assert.NotEqual(t, bikeThingType, batteryThingType, "Bike and battery thing types should be different")
	assert.NotEqual(t, stationThingType, batteryThingType, "Station and battery thing types should be different")
}

// Test IoT Policy configuration
func TestIoTPolicyConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "PolicyConfiguration",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify IoT policy exists
	policyName := terraform.Output(t, terraformOptions, "iot_policy_name")
	assert.NotEmpty(t, policyName, "IoT policy should be created")
	assert.Contains(t, policyName, "iot-policy", "Policy name should contain 'iot-policy'")

	policyARN := terraform.Output(t, terraformOptions, "iot_policy_arn")
	assert.NotEmpty(t, policyARN, "IoT policy ARN should be available")
	assert.Contains(t, policyARN, "policy/", "Should be a policy ARN")
	assert.Contains(t, policyARN, policyName, "Policy ARN should contain policy name")
}

// Test IoT Rules for each message topic
func TestIoTRulesForMessageTopics(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	mockKinesisARN := fmt.Sprintf("arn:aws:kinesis:us-east-1:123456789012:stream/test-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  mockKinesisARN,
			"tags": map[string]string{
				"Test": "IoTRules",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify IoT Rules are created
	iotRules := terraform.OutputMap(t, terraformOptions, "iot_rule_arns")
	assert.NotEmpty(t, iotRules, "IoT Rules should be created")

	// Verify bike telemetry rule
	bikeRuleARN, exists := iotRules["bike_telemetry"]
	assert.True(t, exists, "Bike telemetry rule should exist")
	assert.NotEmpty(t, bikeRuleARN, "Bike telemetry rule ARN should not be empty")

	// Verify station energy rule
	stationEnergyRuleARN, exists := iotRules["station_energy"]
	assert.True(t, exists, "Station energy rule should exist")
	assert.NotEmpty(t, stationEnergyRuleARN, "Station energy rule ARN should not be empty")

	// Verify station swap rule
	stationSwapRuleARN, exists := iotRules["station_swap"]
	assert.True(t, exists, "Station swap rule should exist")
	assert.NotEmpty(t, stationSwapRuleARN, "Station swap rule ARN should not be empty")

	// Verify MQTT topics
	mqttTopics := terraform.OutputMap(t, terraformOptions, "mqtt_topics")
	assert.Equal(t, "ecovolt/bikes/+/telemetry", mqttTopics["bike_telemetry"])
	assert.Equal(t, "ecovolt/stations/+/energy", mqttTopics["station_energy"])
	assert.Equal(t, "ecovolt/stations/+/swap", mqttTopics["station_swap"])
}

// Test IoT Core logging configuration
func TestIoTCoreLoggingConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                true,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "LoggingConfiguration",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify logging is enabled
	loggingEnabled := terraform.Output(t, terraformOptions, "iot_logging_enabled")
	assert.Equal(t, "true", loggingEnabled, "IoT logging should be enabled")

	// Verify logging role exists
	loggingRoleARN := terraform.Output(t, terraformOptions, "iot_logging_role_arn")
	assert.NotEmpty(t, loggingRoleARN, "IoT logging role should exist")
	assert.Contains(t, loggingRoleARN, "role/", "Should be an IAM role ARN")
}

// Test Fleet Indexing configuration
func TestFleetIndexingConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         true,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "FleetIndexing",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Fleet Indexing is enabled
	fleetIndexingEnabled := terraform.Output(t, terraformOptions, "fleet_indexing_enabled")
	assert.Equal(t, "true", fleetIndexingEnabled, "Fleet Indexing should be enabled")

	// Verify fleet index name
	fleetIndexName := terraform.Output(t, terraformOptions, "fleet_index_name")
	assert.Equal(t, "AWS_Things", fleetIndexName, "Fleet index name should be AWS_Things")
}

// Test firmware S3 bucket setup
func TestFirmwareS3BucketSetup(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "FirmwareBucket",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify firmware bucket exists
	firmwareBucket := terraform.Output(t, terraformOptions, "firmware_bucket_name")
	assert.NotEmpty(t, firmwareBucket, "Firmware bucket should be created")
	assert.Contains(t, firmwareBucket, "firmware", "Bucket name should contain 'firmware'")

	firmwareBucketARN := terraform.Output(t, terraformOptions, "firmware_bucket_arn")
	assert.NotEmpty(t, firmwareBucketARN, "Firmware bucket ARN should be available")
	assert.Contains(t, firmwareBucketARN, "s3:::", "Should be an S3 bucket ARN")
	assert.Contains(t, firmwareBucketARN, firmwareBucket, "Bucket ARN should contain bucket name")
}

// Test device management IAM roles
func TestDeviceManagementIAMRoles(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "DeviceManagementRoles",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify device management role exists
	deviceMgmtRole := terraform.Output(t, terraformOptions, "device_management_role_arn")
	assert.NotEmpty(t, deviceMgmtRole, "Device management role should exist")
	assert.Contains(t, deviceMgmtRole, "role/", "Should be an IAM role ARN")

	deviceMgmtRoleName := terraform.Output(t, terraformOptions, "device_management_role_name")
	assert.NotEmpty(t, deviceMgmtRoleName, "Device management role name should be available")
	assert.Contains(t, deviceMgmtRoleName, "device-mgmt", "Role name should contain 'device-mgmt'")

	// Verify IoT Rules role exists
	iotRulesRole := terraform.Output(t, terraformOptions, "iot_rules_role_arn")
	assert.NotEmpty(t, iotRulesRole, "IoT Rules role should exist")
	assert.Contains(t, iotRulesRole, "role/", "Should be an IAM role ARN")

	iotRulesRoleName := terraform.Output(t, terraformOptions, "iot_rules_role_name")
	assert.NotEmpty(t, iotRulesRoleName, "IoT Rules role name should be available")
	assert.Contains(t, iotRulesRoleName, "iot-rules", "Role name should contain 'iot-rules'")
}

// Test IoT endpoint availability
func TestIoTEndpointAvailability(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "IoTEndpoint",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify IoT endpoint
	iotEndpoint := terraform.Output(t, terraformOptions, "iot_endpoint")
	assert.NotEmpty(t, iotEndpoint, "IoT endpoint should be available")
	assert.Contains(t, iotEndpoint, "iot", "Endpoint should contain 'iot'")
	assert.Contains(t, iotEndpoint, "amazonaws.com", "Endpoint should be in AWS domain")

	// Verify endpoint type
	endpointType := terraform.Output(t, terraformOptions, "iot_endpoint_type")
	assert.Equal(t, "iot:Data-ATS", endpointType, "Endpoint type should be Data-ATS")
}

// Test SSM parameter storage
func TestSSMParameterStorage(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "",
			"tags": map[string]string{
				"Test": "SSMParameters",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify SSM parameter prefix
	ssmPrefix := terraform.Output(t, terraformOptions, "ssm_parameter_prefix")
	assert.NotEmpty(t, ssmPrefix, "SSM parameter prefix should be defined")
	assert.Contains(t, ssmPrefix, "/ecovolt/", "SSM prefix should contain /ecovolt/")
	assert.Contains(t, ssmPrefix, "/iot", "SSM prefix should contain /iot")

	// Verify IoT endpoint parameter
	ssmEndpointParam := terraform.Output(t, terraformOptions, "ssm_iot_endpoint_parameter")
	assert.NotEmpty(t, ssmEndpointParam, "IoT endpoint SSM parameter should exist")
	assert.Contains(t, ssmEndpointParam, "/iot/endpoint", "Parameter should have correct path")

	// Verify IoT policy ARN parameter
	ssmPolicyParam := terraform.Output(t, terraformOptions, "ssm_iot_policy_arn_parameter")
	assert.NotEmpty(t, ssmPolicyParam, "IoT policy ARN SSM parameter should exist")
	assert.Contains(t, ssmPolicyParam, "/iot/policy-arn", "Parameter should have correct path")

	// Verify firmware bucket parameter
	ssmFirmwareParam := terraform.Output(t, terraformOptions, "ssm_firmware_bucket_parameter")
	assert.NotEmpty(t, ssmFirmwareParam, "Firmware bucket SSM parameter should exist")
	assert.Contains(t, ssmFirmwareParam, "/iot/firmware-bucket", "Parameter should have correct path")
}

// Test IoT Rules without Kinesis stream (should not create rules)
func TestIoTRulesWithoutKinesisStream(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/iot",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_logging":                false,
			"enable_fleet_indexing":         false,
			"telemetry_kinesis_stream_arn":  "", // Empty - no Kinesis stream
			"tags": map[string]string{
				"Test": "NoKinesisRules",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify IoT Rules are not created when Kinesis stream ARN is empty
	iotRules := terraform.OutputMap(t, terraformOptions, "iot_rule_arns")

	// All rule ARNs should be empty/null
	bikeRuleARN, exists := iotRules["bike_telemetry"]
	if exists {
		assert.Empty(t, bikeRuleARN, "Bike telemetry rule should not be created without Kinesis stream")
	}

	stationEnergyRuleARN, exists := iotRules["station_energy"]
	if exists {
		assert.Empty(t, stationEnergyRuleARN, "Station energy rule should not be created without Kinesis stream")
	}

	stationSwapRuleARN, exists := iotRules["station_swap"]
	if exists {
		assert.Empty(t, stationSwapRuleARN, "Station swap rule should not be created without Kinesis stream")
	}

	// MQTT topics should still be defined
	mqttTopics := terraform.OutputMap(t, terraformOptions, "mqtt_topics")
	assert.NotEmpty(t, mqttTopics, "MQTT topics should be defined even without rules")
}
