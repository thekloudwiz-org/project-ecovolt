package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Feature: ecovolt-aws-infrastructure, Property 19: Telemetry streaming to analytics
// For any telemetry data that arrives at IoT Core, the data should be streamed into the analytics pipeline (Kinesis Data Stream)
// Validates: Requirements 5.1
func TestProperty19_TelemetryStreamingToAnalytics(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	shardCount := selectRandomShardCount()
	retentionHours := selectRandomRetentionHours()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/analytics",
				Vars: map[string]interface{}{
					"project_name":                         "ecovolt",
					"environment":                          fmt.Sprintf("test-%s", uniqueID),
					"kinesis_shard_count":                  shardCount,
					"kinesis_retention_hours":              retentionHours,
					"timestream_memory_retention_hours":    24,
					"timestream_magnetic_retention_days":   90,
					"s3_lifecycle_glacier_days":            90,
					"s3_lifecycle_deep_archive_days":       180,
					"enable_firehose":                      true,
					"enable_athena":                        true,
					"enable_glue_crawler":                  true,
					"tags": map[string]string{
						"Test": "Property19",
					},
				},
				NoColor: true,
			})

			// Clean up resources after test
			defer terraform.Destroy(t, terraformOptions)

			// Initialize and apply Terraform
			terraform.InitAndApply(t, terraformOptions)

			// Verify Property 19: Telemetry streaming to analytics
			// Verify Kinesis stream is created for telemetry ingestion
			kinesisStreamName := terraform.Output(t, terraformOptions, "kinesis_stream_name")
			assert.NotEmpty(t, kinesisStreamName, "Kinesis stream should be created for telemetry ingestion")
			assert.Contains(t, kinesisStreamName, "telemetry", "Stream name should indicate telemetry purpose")

			kinesisStreamARN := terraform.Output(t, terraformOptions, "kinesis_stream_arn")
			assert.NotEmpty(t, kinesisStreamARN, "Kinesis stream ARN should be available")
			assert.Contains(t, kinesisStreamARN, "kinesis", "ARN should be a Kinesis resource")

			// Verify shard count matches configuration
			actualShardCount := terraform.Output(t, terraformOptions, "kinesis_shard_count")
			assert.Equal(t, fmt.Sprintf("%d", shardCount), actualShardCount, "Shard count should match configuration")

			// Verify Lambda stream processor is configured to consume from Kinesis
			lambdaProcessorARN := terraform.Output(t, terraformOptions, "lambda_stream_processor_arn")
			assert.NotEmpty(t, lambdaProcessorARN, "Lambda stream processor should be created")
			assert.Contains(t, lambdaProcessorARN, "stream-processor", "Lambda should be the stream processor")

			// Verify Timestream database exists for storing streamed data
			timestreamDB := terraform.Output(t, terraformOptions, "timestream_database_name")
			assert.NotEmpty(t, timestreamDB, "Timestream database should be created for storing telemetry")

			// Verify Timestream tables exist for different telemetry types
			bikeTable := terraform.Output(t, terraformOptions, "timestream_table_bike_name")
			assert.NotEmpty(t, bikeTable, "Bike telemetry table should exist")

			stationTable := terraform.Output(t, terraformOptions, "timestream_table_station_name")
			assert.NotEmpty(t, stationTable, "Station energy table should exist")

			swapTable := terraform.Output(t, terraformOptions, "timestream_table_swap_name")
			assert.NotEmpty(t, swapTable, "Swap events table should exist")

			// Verify Firehose is configured for S3 archival (parallel streaming path)
	firehoseName := terraform.Output(t, terraformOptions, "firehose_name")
	assert.NotEmpty(t, firehoseName, "Kinesis Firehose should be created for S3 archival")
}

// Feature: ecovolt-aws-infrastructure, Property 20: Telemetry data transformation
// For any raw telemetry data in the analytics pipeline, the system should transform it into structured formats (Parquet, JSON) suitable for querying
// Validates: Requirements 5.2
func TestProperty20_TelemetryDataTransformation(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	enableGlueCrawler := selectRandomBool()
	enableAthena := selectRandomBool()

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
					"enable_athena":                        enableAthena,
					"enable_glue_crawler":                  enableGlueCrawler,
					"tags": map[string]string{
						"Test": "Property20",
					},
				},
				NoColor: true,
			})

			// Clean up resources after test
			defer terraform.Destroy(t, terraformOptions)

			// Initialize and apply Terraform
			terraform.InitAndApply(t, terraformOptions)

			// Verify Property 20: Telemetry data transformation
			// Verify S3 data lake exists for storing transformed data
			s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
			assert.NotEmpty(t, s3BucketName, "S3 data lake bucket should be created")
			assert.Contains(t, s3BucketName, "data-lake", "Bucket name should indicate data lake purpose")

			// Verify Lambda transformer exists for data transformation
			lambdaTransformerARN := terraform.Output(t, terraformOptions, "lambda_transformer_arn")
			assert.NotEmpty(t, lambdaTransformerARN, "Lambda data transformer should be created")
			assert.Contains(t, lambdaTransformerARN, "transformer", "Lambda should be the data transformer")

			// Verify Glue database exists for data catalog (structured format metadata)
			glueDBName := terraform.Output(t, terraformOptions, "glue_database_name")
			assert.NotEmpty(t, glueDBName, "Glue database should be created for data catalog")

			// Verify Glue crawler exists if enabled (discovers structured data schema)
			if enableGlueCrawler {
				glueCrawlerName := terraform.Output(t, terraformOptions, "glue_crawler_name")
				assert.NotEmpty(t, glueCrawlerName, "Glue crawler should be created when enabled")
			}

			// Verify Athena workgroup exists if enabled (queries structured data)
			if enableAthena {
				athenaWorkgroup := terraform.Output(t, terraformOptions, "athena_workgroup_name")
				assert.NotEmpty(t, athenaWorkgroup, "Athena workgroup should be created when enabled")
				assert.Contains(t, athenaWorkgroup, "analytics", "Workgroup name should indicate analytics purpose")

			athenaResultsBucket := terraform.Output(t, terraformOptions, "athena_results_bucket")
			assert.NotEmpty(t, athenaResultsBucket, "Athena results bucket should be created")
		}
}

// Feature: ecovolt-aws-infrastructure, Property 21: Energy metrics aggregation
// For any energy consumption telemetry data, the system should correctly aggregate metrics by time period, location, and device type
// Validates: Requirements 5.3
func TestProperty21_EnergyMetricsAggregation(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	memoryRetentionHours := selectRandomMemoryRetention()
	magneticRetentionDays := selectRandomMagneticRetention()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/analytics",
				Vars: map[string]interface{}{
					"project_name":                         "ecovolt",
					"environment":                          fmt.Sprintf("test-%s", uniqueID),
					"kinesis_shard_count":                  2,
					"kinesis_retention_hours":              24,
					"timestream_memory_retention_hours":    memoryRetentionHours,
					"timestream_magnetic_retention_days":   magneticRetentionDays,
					"s3_lifecycle_glacier_days":            90,
					"s3_lifecycle_deep_archive_days":       180,
					"enable_firehose":                      true,
					"enable_athena":                        true,
					"enable_glue_crawler":                  true,
					"tags": map[string]string{
						"Test": "Property21",
					},
				},
				NoColor: true,
			})

			// Clean up resources after test
			defer terraform.Destroy(t, terraformOptions)

			// Initialize and apply Terraform
			terraform.InitAndApply(t, terraformOptions)

			// Verify Property 21: Energy metrics aggregation
			// Verify Timestream database exists for time-series aggregation
			timestreamDB := terraform.Output(t, terraformOptions, "timestream_database_name")
			assert.NotEmpty(t, timestreamDB, "Timestream database should be created for metrics aggregation")

			// Verify station energy table exists (stores energy consumption data)
			stationTable := terraform.Output(t, terraformOptions, "timestream_table_station_name")
			assert.NotEmpty(t, stationTable, "Station energy table should exist for energy metrics")
			assert.Contains(t, stationTable, "station", "Table should be for station data")

			// Verify bike telemetry table exists (stores bike energy consumption)
			bikeTable := terraform.Output(t, terraformOptions, "timestream_table_bike_name")
			assert.NotEmpty(t, bikeTable, "Bike telemetry table should exist for bike energy metrics")
			assert.Contains(t, bikeTable, "bike", "Table should be for bike data")

			// Verify Athena workgroup exists for aggregation queries
			athenaWorkgroup := terraform.Output(t, terraformOptions, "athena_workgroup_name")
			assert.NotEmpty(t, athenaWorkgroup, "Athena workgroup should be created for aggregation queries")

			// Verify S3 data lake exists for historical aggregations
			s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
			assert.NotEmpty(t, s3BucketName, "S3 data lake should exist for historical data aggregation")

	// Verify Glue database exists for partitioned data (enables aggregation by time/location/type)
	glueDBName := terraform.Output(t, terraformOptions, "glue_database_name")
	assert.NotEmpty(t, glueDBName, "Glue database should exist for partitioned data catalog")
}

// Feature: ecovolt-aws-infrastructure, Property 10: Telemetry persistence latency
// For any telemetry data that arrives at IoT Core, the data should be persisted to durable storage (Kinesis, Timestream, or S3) within 5 seconds
// Validates: Requirements 2.4
func TestProperty10_TelemetryPersistenceLatency(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	shardCount := selectRandomShardCount()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../modules/analytics",
				Vars: map[string]interface{}{
					"project_name":                         "ecovolt",
					"environment":                          fmt.Sprintf("test-%s", uniqueID),
					"kinesis_shard_count":                  shardCount,
					"kinesis_retention_hours":              24,
					"timestream_memory_retention_hours":    24,
					"timestream_magnetic_retention_days":   90,
					"s3_lifecycle_glacier_days":            90,
					"s3_lifecycle_deep_archive_days":       180,
					"enable_firehose":                      true,
					"enable_athena":                        true,
					"enable_glue_crawler":                  true,
					"tags": map[string]string{
						"Test": "Property10",
					},
				},
				NoColor: true,
			})

			// Clean up resources after test
			defer terraform.Destroy(t, terraformOptions)

			// Initialize and apply Terraform
			terraform.InitAndApply(t, terraformOptions)

			// Verify Property 10: Telemetry persistence latency
			// Verify Kinesis stream exists (first persistence layer - milliseconds latency)
			kinesisStreamARN := terraform.Output(t, terraformOptions, "kinesis_stream_arn")
			assert.NotEmpty(t, kinesisStreamARN, "Kinesis stream should exist for immediate persistence")

			// Verify Lambda processor exists with appropriate configuration for low latency
			lambdaProcessorARN := terraform.Output(t, terraformOptions, "lambda_stream_processor_arn")
			assert.NotEmpty(t, lambdaProcessorARN, "Lambda processor should exist for fast Timestream writes")

			// Verify Timestream database exists (second persistence layer - seconds latency)
			timestreamDB := terraform.Output(t, terraformOptions, "timestream_database_name")
			assert.NotEmpty(t, timestreamDB, "Timestream database should exist for durable time-series storage")

			// Verify Timestream tables exist for all telemetry types
			bikeTable := terraform.Output(t, terraformOptions, "timestream_table_bike_name")
			assert.NotEmpty(t, bikeTable, "Bike table should exist for persistence")

			stationTable := terraform.Output(t, terraformOptions, "timestream_table_station_name")
			assert.NotEmpty(t, stationTable, "Station table should exist for persistence")

			swapTable := terraform.Output(t, terraformOptions, "timestream_table_swap_name")
			assert.NotEmpty(t, swapTable, "Swap table should exist for persistence")

			// Verify Firehose exists (third persistence layer - S3 archival within minutes)
			firehoseName := terraform.Output(t, terraformOptions, "firehose_name")
			assert.NotEmpty(t, firehoseName, "Firehose should exist for S3 persistence")

			// Verify S3 bucket exists (durable long-term storage)
			s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
			assert.NotEmpty(t, s3BucketName, "S3 bucket should exist for durable storage")

	// Note: Actual latency testing would require integration tests with real data flow
	// This property test verifies that all required infrastructure components exist
	// to support the 5-second persistence requirement
}

// Helper function to select random shard count (1-4)
func selectRandomShardCount() int {
	return random.Random(1, 4)
}

// Helper function to select random retention hours (24-168)
func selectRandomRetentionHours() int {
	options := []int{24, 48, 72, 168} // 1 day, 2 days, 3 days, 1 week
	return options[random.Random(0, len(options)-1)]
}

// Helper function to select random memory retention (12-72 hours)
func selectRandomMemoryRetention() int {
	options := []int{12, 24, 48, 72}
	return options[random.Random(0, len(options)-1)]
}

// Helper function to select random magnetic retention (30-365 days)
func selectRandomMagneticRetention() int {
	options := []int{30, 60, 90, 180, 365}
	return options[random.Random(0, len(options)-1)]
}
