# Analytics Module

This module creates the analytics pipeline for EcoVolt telemetry data processing, including real-time streaming, time-series storage, data lake archival, and query capabilities.

## Architecture

```
IoT Core → Kinesis Data Stream → Lambda Processor → Timestream
                ↓
         Kinesis Firehose → S3 Data Lake → Glue Crawler → Athena
                                    ↓
                            Lambda Transformer
                                    ↓
                            Parquet (Structured)
```

## Components

### Kinesis Data Stream
- **Purpose**: Real-time telemetry ingestion from IoT Core
- **Configuration**: Configurable shard count and retention period
- **Encryption**: Optional KMS encryption
- **Metrics**: Comprehensive CloudWatch metrics enabled

### Timestream Database
- **Purpose**: Time-series storage for fast queries on recent data
- **Tables**:
  - `bike-telemetry`: bike battery, location, and operational data
  - `station-energy`: Solar generation and grid consumption data
  - `swap-events`: Battery swap transaction records
- **Lifecycle**: Automatic data tiering (memory → magnetic storage)
- **Retention**: Configurable memory and magnetic store retention

### S3 Data Lake
- **Purpose**: Long-term storage and historical analysis
- **Structure**:
  - `raw/`: Raw JSON data from Kinesis Firehose
  - `processed/`: Transformed Parquet data
  - `errors/`: Failed records for debugging
- **Lifecycle**: Automatic transition to Glacier and Deep Archive
- **Encryption**: Server-side encryption (AES256 or KMS)

### Lambda Functions

#### Stream Processor
- **Trigger**: Kinesis Data Stream
- **Purpose**: Process telemetry records and write to Timestream
- **Batch Size**: 100 records
- **Timeout**: 60 seconds
- **Memory**: 256 MB

#### Data Transformer
- **Trigger**: S3 event (optional) or scheduled
- **Purpose**: Transform raw JSON to structured Parquet format
- **Features**:
  - Flattens nested JSON structures
  - Partitions by date (year/month/day)
  - Compresses with Snappy
- **Timeout**: 300 seconds
- **Memory**: 512 MB

### Kinesis Data Firehose
- **Purpose**: Archive raw data to S3
- **Buffering**: 5 MB or 5 minutes (whichever comes first)
- **Compression**: GZIP
- **Partitioning**: Automatic date-based partitioning

### Glue Data Catalog
- **Purpose**: Metadata catalog for data lake
- **Crawler**: Automatically discovers schema from S3 data
- **Schedule**: Daily at 2 AM UTC
- **Schema Evolution**: Automatically updates on schema changes

### Athena Workgroup
- **Purpose**: SQL queries on data lake
- **Results**: Stored in dedicated S3 bucket
- **Encryption**: SSE-S3
- **Metrics**: CloudWatch metrics enabled

## Usage

### Basic Configuration

```hcl
module "analytics" {
  source = "./modules/analytics"

  project_name = "ecovolt"
  environment  = "prod"

  kinesis_shard_count      = 4
  kinesis_retention_hours  = 24

  timestream_memory_retention_hours   = 24
  timestream_magnetic_retention_days  = 90

  s3_lifecycle_glacier_days       = 90
  s3_lifecycle_deep_archive_days  = 180

  enable_firehose      = true
  enable_athena        = true
  enable_glue_crawler  = true

  kms_key_arn = module.security.kms_key_arn

  tags = {
    Project     = "EcoVolt"
    Environment = "Production"
  }
}
```

### With IoT Module Integration

```hcl
module "iot" {
  source = "./modules/iot"
  
  # ... other configuration ...
  
  telemetry_kinesis_stream_arn = module.analytics.kinesis_stream_arn
}
```

### Querying Data with Athena

```sql
-- Query bike telemetry
SELECT 
  bikeId,
  AVG(battery_stateOfCharge) as avg_soc,
  MAX(speed) as max_speed
FROM ecovolt_prod_data_lake.bike_telemetry
WHERE year = '2024' AND month = '01'
GROUP BY bikeId;

-- Query station energy production
SELECT 
  stationId,
  SUM(solar_powerGenerated) as total_solar_kwh,
  SUM(grid_powerConsumed) as total_grid_kwh
FROM ecovolt_prod_data_lake.station_energy
WHERE year = '2024' AND month = '01'
GROUP BY stationId;
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | "ecovolt" | no |
| environment | Environment name (dev, staging, prod) | string | - | yes |
| kinesis_stream_name | Kinesis stream name (auto-generated if empty) | string | "" | no |
| kinesis_shard_count | Number of Kinesis shards | number | 2 | no |
| kinesis_retention_hours | Kinesis retention period (24-8760 hours) | number | 24 | no |
| timestream_database_name | Timestream database name (auto-generated if empty) | string | "" | no |
| timestream_memory_retention_hours | Timestream memory retention (1-8766 hours) | number | 24 | no |
| timestream_magnetic_retention_days | Timestream magnetic retention (1-73000 days) | number | 90 | no |
| s3_bucket_name | S3 data lake bucket name (auto-generated if empty) | string | "" | no |
| s3_lifecycle_glacier_days | Days before Glacier transition (min 30) | number | 90 | no |
| s3_lifecycle_deep_archive_days | Days before Deep Archive transition (min 90) | number | 180 | no |
| glue_database_name | Glue database name (auto-generated if empty) | string | "" | no |
| enable_firehose | Enable Kinesis Firehose for S3 archival | bool | true | no |
| enable_athena | Enable Athena workgroup | bool | true | no |
| enable_glue_crawler | Enable Glue crawler | bool | true | no |
| kms_key_arn | KMS key ARN for encryption | string | "" | no |
| tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| kinesis_stream_name | Kinesis Data Stream name |
| kinesis_stream_arn | Kinesis Data Stream ARN |
| timestream_database_name | Timestream database name |
| timestream_database_arn | Timestream database ARN |
| timestream_table_bike_name | Bike telemetry table name |
| timestream_table_station_name | Station energy table name |
| timestream_table_swap_name | Swap events table name |
| s3_bucket_name | S3 data lake bucket name |
| s3_bucket_arn | S3 data lake bucket ARN |
| glue_database_name | Glue catalog database name |
| lambda_stream_processor_arn | Stream processor Lambda ARN |
| lambda_transformer_arn | Data transformer Lambda ARN |
| firehose_name | Kinesis Firehose name (if enabled) |
| athena_workgroup_name | Athena workgroup name (if enabled) |

## Data Flow

### Real-Time Path
1. IoT devices publish telemetry to IoT Core
2. IoT Rules route messages to Kinesis Data Stream
3. Lambda Stream Processor consumes from Kinesis
4. Lambda writes structured data to Timestream
5. Applications query Timestream for real-time insights

### Archival Path
1. Kinesis Firehose reads from Kinesis Data Stream
2. Firehose buffers and compresses data
3. Firehose writes raw JSON to S3 (partitioned by date)
4. Glue Crawler discovers schema
5. Athena queries historical data

### Transformation Path
1. Lambda Transformer triggered by S3 events or schedule
2. Reads raw JSON from S3
3. Transforms to Parquet with partitioning
4. Writes structured data back to S3
5. Athena queries optimized Parquet files

## Performance Considerations

### Kinesis Shards
- Each shard supports 1 MB/s or 1000 records/s ingestion
- Calculate required shards: `ceil(peak_throughput_MB_per_sec / 1)`
- Example: 10,000 devices × 1 KB/message × 1 message/min = ~167 KB/s = 1 shard

### Timestream Costs
- Memory store: $0.036/GB-hour
- Magnetic store: $0.03/GB-month
- Queries: $0.01/GB scanned
- Optimize by setting appropriate retention periods

### S3 Storage Classes
- Standard: Frequent access (< 30 days)
- Glacier: Infrequent access (30-180 days)
- Deep Archive: Long-term archival (> 180 days)

### Athena Query Optimization
- Use Parquet format (10x faster than JSON)
- Partition by date for time-range queries
- Use columnar projection to reduce data scanned
- Compress with Snappy or GZIP

## Monitoring

### CloudWatch Metrics

**Kinesis Stream**:
- `IncomingRecords`: Records per second
- `IncomingBytes`: Bytes per second
- `IteratorAgeMilliseconds`: Processing lag
- `WriteProvisionedThroughputExceeded`: Throttling

**Lambda Functions**:
- `Invocations`: Function invocation count
- `Errors`: Error count
- `Duration`: Execution time
- `ConcurrentExecutions`: Concurrent invocations

**Timestream**:
- `SystemErrors`: Write errors
- `UserErrors`: Invalid data errors
- `MagneticStoreRejectedRecordCount`: Rejected records

### Alarms

Recommended CloudWatch Alarms:
- Kinesis iterator age > 60 seconds
- Lambda error rate > 1%
- Timestream write errors > 10/minute
- Firehose delivery failures > 5/hour

## Cost Estimation

### Example: 10,000 devices, 1 message/minute

**Kinesis Data Stream**:
- Shard hours: 2 shards × 730 hours = 1,460 shard-hours
- PUT payload units: 10,000 × 60 × 24 × 30 × 1 KB / 25 KB = 17.28M units
- Cost: ~$50/month

**Timestream**:
- Memory store: 10 GB × 24 hours × $0.036 = ~$9/day
- Magnetic store: 300 GB × $0.03 = ~$9/month
- Cost: ~$280/month

**S3 Data Lake**:
- Standard storage: 100 GB × $0.023 = ~$2.30/month
- Glacier: 500 GB × $0.004 = ~$2/month
- Cost: ~$5/month

**Lambda**:
- Invocations: 432M/month (within free tier)
- Duration: Minimal cost
- Cost: ~$5/month

**Total**: ~$340/month

## Troubleshooting

### High Kinesis Iterator Age
- **Cause**: Lambda processing slower than ingestion rate
- **Solution**: Increase Lambda concurrency or shard count

### Timestream Write Errors
- **Cause**: Invalid data format or schema mismatch
- **Solution**: Check Lambda logs, validate data structure

### Athena Query Timeout
- **Cause**: Scanning too much data
- **Solution**: Use partitioning, Parquet format, column projection

### Firehose Delivery Failures
- **Cause**: S3 permissions or invalid data
- **Solution**: Check IAM role permissions, review error logs

## Security

### Encryption
- **At Rest**: KMS encryption for Kinesis, Timestream, and S3
- **In Transit**: TLS 1.2+ for all service communication

### IAM Roles
- **Lambda Processor**: Read Kinesis, Write Timestream
- **Lambda Transformer**: Read/Write S3
- **Firehose**: Read Kinesis, Write S3
- **Glue Crawler**: Read S3, Write Glue Catalog

### Network Security
- Lambda functions can be deployed in VPC for private subnet access
- S3 buckets have public access blocked
- VPC endpoints available for AWS service access

## References

- [Amazon Kinesis Data Streams](https://docs.aws.amazon.com/kinesis/latest/dev/)
- [Amazon Timestream](https://docs.aws.amazon.com/timestream/)
- [Amazon Athena](https://docs.aws.amazon.com/athena/)
- [AWS Glue](https://docs.aws.amazon.com/glue/)
- [Kinesis Data Firehose](https://docs.aws.amazon.com/firehose/)
