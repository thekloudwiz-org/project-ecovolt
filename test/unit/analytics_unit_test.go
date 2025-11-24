package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test Kinesis stream creation and configuration
func TestKinesisStreamCreation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  3,
			"kinesis_retention_hours":              48,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      true,
			"enable_athena":                        true,
			"enable_glue_crawler":                  true,
			"tags": map[string]string{
				"Test": "KinesisStream",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Kinesis stream created
	streamName := terraform.Output(t, terraformOptions, "kinesis_stream_name")
	assert.NotEmpty(t, streamName, "Kinesis stream name should not be empty")
	assert.Contains(t, streamName, "telemetry", "Stream name should contain 'telemetry'")

	streamARN := terraform.Output(t, terraformOptions, "kinesis_stream_arn")
	assert.NotEmpty(t, streamARN, "Kinesis stream ARN should not be empty")
	assert.Contains(t, streamARN, "kinesis", "ARN should be a Kinesis resource")

	// Verify shard count
	shardCount := terraform.Output(t, terraformOptions, "kinesis_shard_count")
	assert.Equal(t, "3", shardCount, "Shard count should match configuration")
}

// Test Timestream database and table creation
func TestTimestreamDatabaseAndTables(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    48,
			"timestream_magnetic_retention_days":   180,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      false,
			"enable_athena":                        false,
			"enable_glue_crawler":                  false,
			"tags": map[string]string{
				"Test": "Timestream",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Timestream database
	dbName := terraform.Output(t, terraformOptions, "timestream_database_name")
	assert.NotEmpty(t, dbName, "Timestream database name should not be empty")
	assert.Contains(t, dbName, "telemetry", "Database name should contain 'telemetry'")

	dbARN := terraform.Output(t, terraformOptions, "timestream_database_arn")
	assert.NotEmpty(t, dbARN, "Timestream database ARN should not be empty")
	assert.Contains(t, dbARN, "timestream", "ARN should be a Timestream resource")

	// Verify bike telemetry table
	bikeTable := terraform.Output(t, terraformOptions, "timestream_table_bike_name")
	assert.NotEmpty(t, bikeTable, "Bike table should be created")
	assert.Contains(t, bikeTable, "bike", "Table name should contain 'bike'")

	bikeTableARN := terraform.Output(t, terraformOptions, "timestream_table_bike_arn")
	assert.NotEmpty(t, bikeTableARN, "Bike table ARN should not be empty")

	// Verify station energy table
	stationTable := terraform.Output(t, terraformOptions, "timestream_table_station_name")
	assert.NotEmpty(t, stationTable, "Station table should be created")
	assert.Contains(t, stationTable, "station", "Table name should contain 'station'")

	stationTableARN := terraform.Output(t, terraformOptions, "timestream_table_station_arn")
	assert.NotEmpty(t, stationTableARN, "Station table ARN should not be empty")

	// Verify swap events table
	swapTable := terraform.Output(t, terraformOptions, "timestream_table_swap_name")
	assert.NotEmpty(t, swapTable, "Swap table should be created")
	assert.Contains(t, swapTable, "swap", "Table name should contain 'swap'")

	swapTableARN := terraform.Output(t, terraformOptions, "timestream_table_swap_arn")
	assert.NotEmpty(t, swapTableARN, "Swap table ARN should not be empty")
}

// Test S3 bucket lifecycle policies
func TestS3BucketLifecyclePolicies(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            60,
			"s3_lifecycle_deep_archive_days":       120,
			"enable_firehose":                      true,
			"enable_athena":                        true,
			"enable_glue_crawler":                  true,
			"tags": map[string]string{
				"Test": "S3Lifecycle",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify S3 data lake bucket
	bucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, bucketName, "S3 bucket should be created")
	assert.Contains(t, bucketName, "data-lake", "Bucket name should contain 'data-lake'")

	bucketARN := terraform.Output(t, terraformOptions, "s3_bucket_arn")
	assert.NotEmpty(t, bucketARN, "S3 bucket ARN should not be empty")
	assert.Contains(t, bucketARN, "s3", "ARN should be an S3 resource")

	// Note: Lifecycle policies are configured in Terraform but cannot be directly
	// verified through outputs. Integration tests would verify actual lifecycle behavior.
}

// Test Lambda function deployment
func TestLambdaFunctionDeployment(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      true,
			"enable_athena":                        true,
			"enable_glue_crawler":                  true,
			"tags": map[string]string{
				"Test": "Lambda",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Lambda stream processor
	processorName := terraform.Output(t, terraformOptions, "lambda_stream_processor_name")
	assert.NotEmpty(t, processorName, "Lambda stream processor should be created")
	assert.Contains(t, processorName, "stream-processor", "Function name should contain 'stream-processor'")

	processorARN := terraform.Output(t, terraformOptions, "lambda_stream_processor_arn")
	assert.NotEmpty(t, processorARN, "Lambda processor ARN should not be empty")
	assert.Contains(t, processorARN, "lambda", "ARN should be a Lambda resource")

	// Verify Lambda data transformer
	transformerName := terraform.Output(t, terraformOptions, "lambda_transformer_name")
	assert.NotEmpty(t, transformerName, "Lambda transformer should be created")
	assert.Contains(t, transformerName, "transformer", "Function name should contain 'transformer'")

	transformerARN := terraform.Output(t, terraformOptions, "lambda_transformer_arn")
	assert.NotEmpty(t, transformerARN, "Lambda transformer ARN should not be empty")
	assert.Contains(t, transformerARN, "lambda", "ARN should be a Lambda resource")

	// Verify IAM roles
	processorRoleARN := terraform.Output(t, terraformOptions, "lambda_processor_role_arn")
	assert.NotEmpty(t, processorRoleARN, "Lambda processor role should be created")
	assert.Contains(t, processorRoleARN, "iam", "ARN should be an IAM resource")

	transformerRoleARN := terraform.Output(t, terraformOptions, "lambda_transformer_role_arn")
	assert.NotEmpty(t, transformerRoleARN, "Lambda transformer role should be created")
	assert.Contains(t, transformerRoleARN, "iam", "ARN should be an IAM resource")
}

// Test Glue database configuration
func TestGlueDatabaseConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      true,
			"enable_athena":                        true,
			"enable_glue_crawler":                  true,
			"tags": map[string]string{
				"Test": "Glue",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Glue database
	glueDBName := terraform.Output(t, terraformOptions, "glue_database_name")
	assert.NotEmpty(t, glueDBName, "Glue database should be created")
	assert.Contains(t, glueDBName, "data_lake", "Database name should contain 'data_lake'")

	glueDBARN := terraform.Output(t, terraformOptions, "glue_database_arn")
	assert.NotEmpty(t, glueDBARN, "Glue database ARN should not be empty")
	assert.Contains(t, glueDBARN, "glue", "ARN should be a Glue resource")

	// Verify Glue crawler
	crawlerName := terraform.Output(t, terraformOptions, "glue_crawler_name")
	assert.NotEmpty(t, crawlerName, "Glue crawler should be created")
	assert.Contains(t, crawlerName, "crawler", "Crawler name should contain 'crawler'")

	crawlerARN := terraform.Output(t, terraformOptions, "glue_crawler_arn")
	assert.NotEmpty(t, crawlerARN, "Glue crawler ARN should not be empty")

	// Verify Glue crawler IAM role
	crawlerRoleARN := terraform.Output(t, terraformOptions, "glue_crawler_role_arn")
	assert.NotEmpty(t, crawlerRoleARN, "Glue crawler role should be created")
	assert.Contains(t, crawlerRoleARN, "iam", "ARN should be an IAM resource")
}

// Test Kinesis Firehose configuration
func TestKinesisFirehoseConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      true,
			"enable_athena":                        false,
			"enable_glue_crawler":                  false,
			"tags": map[string]string{
				"Test": "Firehose",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Firehose delivery stream
	firehoseName := terraform.Output(t, terraformOptions, "firehose_name")
	assert.NotEmpty(t, firehoseName, "Firehose delivery stream should be created")
	assert.Contains(t, firehoseName, "firehose", "Stream name should contain 'firehose'")

	firehoseARN := terraform.Output(t, terraformOptions, "firehose_arn")
	assert.NotEmpty(t, firehoseARN, "Firehose ARN should not be empty")
	assert.Contains(t, firehoseARN, "firehose", "ARN should be a Firehose resource")

	// Verify Firehose IAM role
	firehoseRoleARN := terraform.Output(t, terraformOptions, "firehose_role_arn")
	assert.NotEmpty(t, firehoseRoleARN, "Firehose role should be created")
	assert.Contains(t, firehoseRoleARN, "iam", "ARN should be an IAM resource")
}

// Test Athena workgroup configuration
func TestAthenaWorkgroupConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      false,
			"enable_athena":                        true,
			"enable_glue_crawler":                  false,
			"tags": map[string]string{
				"Test": "Athena",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Athena workgroup
	workgroupName := terraform.Output(t, terraformOptions, "athena_workgroup_name")
	assert.NotEmpty(t, workgroupName, "Athena workgroup should be created")
	assert.Contains(t, workgroupName, "analytics", "Workgroup name should contain 'analytics'")

	workgroupARN := terraform.Output(t, terraformOptions, "athena_workgroup_arn")
	assert.NotEmpty(t, workgroupARN, "Athena workgroup ARN should not be empty")
	assert.Contains(t, workgroupARN, "athena", "ARN should be an Athena resource")

	// Verify Athena results bucket
	resultsBucket := terraform.Output(t, terraformOptions, "athena_results_bucket")
	assert.NotEmpty(t, resultsBucket, "Athena results bucket should be created")
	assert.Contains(t, resultsBucket, "athena-results", "Bucket name should contain 'athena-results'")
}

// Test optional features disabled
func TestOptionalFeaturesDisabled(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  2,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    24,
			"timestream_magnetic_retention_days":   90,
			"s3_lifecycle_glacier_days":            90,
			"s3_lifecycle_deep_archive_days":       180,
			"enable_firehose":                      false,
			"enable_athena":                        false,
			"enable_glue_crawler":                  false,
			"tags": map[string]string{
				"Test": "OptionalDisabled",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify core resources still created
	kinesisStreamName := terraform.Output(t, terraformOptions, "kinesis_stream_name")
	assert.NotEmpty(t, kinesisStreamName, "Kinesis stream should be created")

	timestreamDB := terraform.Output(t, terraformOptions, "timestream_database_name")
	assert.NotEmpty(t, timestreamDB, "Timestream database should be created")

	s3Bucket := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, s3Bucket, "S3 bucket should be created")

	// Verify optional resources not created
	firehoseName := terraform.Output(t, terraformOptions, "firehose_name")
	assert.Empty(t, firehoseName, "Firehose should not be created when disabled")

	athenaWorkgroup := terraform.Output(t, terraformOptions, "athena_workgroup_name")
	assert.Empty(t, athenaWorkgroup, "Athena workgroup should not be created when disabled")

	glueCrawler := terraform.Output(t, terraformOptions, "glue_crawler_name")
	assert.Empty(t, glueCrawler, "Glue crawler should not be created when disabled")
}

// Test minimum configuration
func TestMinimumConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/analytics",
		Vars: map[string]interface{}{
			"project_name":                         "ecovolt",
			"environment":                          fmt.Sprintf("test-%s", uniqueID),
			"kinesis_shard_count":                  1,
			"kinesis_retention_hours":              24,
			"timestream_memory_retention_hours":    1,
			"timestream_magnetic_retention_days":   1,
			"s3_lifecycle_glacier_days":            30,
			"s3_lifecycle_deep_archive_days":       90,
			"enable_firehose":                      false,
			"enable_athena":                        false,
			"enable_glue_crawler":                  false,
			"tags": map[string]string{
				"Test": "MinimumConfig",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify minimum resources created
	kinesisStreamName := terraform.Output(t, terraformOptions, "kinesis_stream_name")
	assert.NotEmpty(t, kinesisStreamName, "Kinesis stream should be created with minimum config")

	shardCount := terraform.Output(t, terraformOptions, "kinesis_shard_count")
	assert.Equal(t, "1", shardCount, "Should have minimum 1 shard")

	timestreamDB := terraform.Output(t, terraformOptions, "timestream_database_name")
	assert.NotEmpty(t, timestreamDB, "Timestream database should be created with minimum config")

	s3Bucket := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, s3Bucket, "S3 bucket should be created with minimum config")
}
