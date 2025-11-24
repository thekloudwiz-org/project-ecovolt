# IoT Module

This module creates AWS IoT Core resources for the EcoVolt infrastructure, enabling secure device connectivity, telemetry ingestion, and device management for electric bikes, swap stations, and batteries.

## Features

- **Device Types**: Thing type definitions for bikes, stations, and batteries
- **Device Authentication**: X.509 certificate-based authentication via IoT policies
- **Message Routing**: IoT Rules for routing telemetry to Kinesis streams
- **Device Management**: IAM roles and permissions for device lifecycle operations
- **Firmware Updates**: S3 bucket for firmware storage with versioning
- **Fleet Indexing**: Search and query capabilities across device fleet
- **Logging**: CloudWatch logging for IoT Core operations
- **Diagnostics**: Remote logging and troubleshooting capabilities

## Usage

```hcl
module "iot" {
  source = "./modules/iot"

  project_name = "ecovolt"
  environment  = "prod"

  # Kinesis stream for telemetry data
  telemetry_kinesis_stream_arn = module.analytics.kinesis_stream_arn

  # Enable optional features
  enable_logging        = true
  enable_fleet_indexing = true

  tags = {
    Project     = "EcoVolt"
    Environment = "Production"
  }
}
```

## MQTT Topics

The module configures the following MQTT topic patterns:

- **Bike Telemetry**: `ecovolt/bikes/{bikeId}/telemetry`
- **Station Energy**: `ecovolt/stations/{stationId}/energy`
- **Battery Swap Events**: `ecovolt/stations/{stationId}/swap`

## Device Authentication

Devices authenticate using X.509 certificates. The IoT policy grants permissions based on the device's Thing Name:

- Connect to IoT Core
- Publish to device-specific topics
- Subscribe to device-specific topics
- Update and retrieve device shadows

## Device Management

The module creates an IAM role for device management operations including:

- Thing creation, update, and deletion
- Thing group management
- IoT Jobs for firmware updates
- Fleet indexing queries
- Access to firmware S3 bucket

## Firmware Updates

Firmware images are stored in a versioned S3 bucket with:

- Server-side encryption (AES256)
- Versioning enabled for rollback capability
- Public access blocked
- Lifecycle policies for cost optimization

## Fleet Indexing

When enabled, Fleet Indexing provides:

- Search across device registry and shadows
- Query by device attributes (model, manufacturer, serial number)
- Connectivity status tracking
- Custom field indexing

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Project name used in resource naming | `string` | `"ecovolt"` | no |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| iot_policy_name | Name for IoT policy | `string` | `""` | no |
| telemetry_kinesis_stream_arn | ARN of Kinesis stream for telemetry | `string` | `""` | no |
| enable_logging | Enable IoT Core logging | `bool` | `true` | no |
| enable_fleet_indexing | Enable IoT Fleet Indexing | `bool` | `true` | no |
| firmware_s3_bucket | S3 bucket name for firmware images | `string` | `""` | no |
| enable_device_defender | Enable IoT Device Defender | `bool` | `false` | no |
| tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| iot_endpoint | IoT Core MQTT endpoint |
| iot_policy_arn | IoT policy ARN |
| iot_rule_arns | Map of IoT rule names to ARNs |
| bike_thing_type_name | Bike thing type name |
| station_thing_type_name | Station thing type name |
| battery_thing_type_name | Battery thing type name |
| firmware_bucket_name | S3 bucket name for firmware images |
| device_management_role_arn | IAM role ARN for device management |
| fleet_index_name | Fleet index name for device queries |
| mqtt_topics | MQTT topic patterns for device communication |

## SSM Parameters

The module stores resource identifiers in SSM Parameter Store:

- `/ecovolt/{environment}/iot/endpoint` - IoT Core endpoint
- `/ecovolt/{environment}/iot/policy-arn` - IoT policy ARN
- `/ecovolt/{environment}/iot/thing-types/bike-arn` - Bike thing type ARN
- `/ecovolt/{environment}/iot/thing-types/station-arn` - Station thing type ARN
- `/ecovolt/{environment}/iot/thing-types/battery-arn` - Battery thing type ARN
- `/ecovolt/{environment}/iot/firmware-bucket` - Firmware S3 bucket name
- `/ecovolt/{environment}/iot/device-mgmt-role-arn` - Device management role ARN
- `/ecovolt/{environment}/iot/mqtt-topics` - MQTT topic patterns (JSON)

## Device Registration Example

```bash
# Create a bike thing
aws iot create-thing \
  --thing-name "bike-001" \
  --thing-type-name "ecovolt-prod-bike" \
  --attribute-payload '{"attributes":{"model":"EB-100","manufacturer":"EcoVolt","serialNumber":"BIKE001"}}'

# Create and attach certificate
aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile vehicle-001-cert.pem \
  --public-key-outfile vehicle-001-public.key \
  --private-key-outfile vehicle-001-private.key

# Attach policy to certificate
aws iot attach-policy \
  --policy-name "ecovolt-prod-iot-policy" \
  --target "arn:aws:iot:region:account:cert/certificate-id"

# Attach certificate to thing
aws iot attach-thing-principal \
  --thing-name "bike-001" \
  --principal "arn:aws:iot:region:account:cert/certificate-id"
```

## Firmware Update Example

```bash
# Upload firmware to S3
aws s3 cp firmware-v2.0.bin s3://ecovolt-prod-firmware/bikes/firmware-v2.0.bin

# Create IoT Job for firmware update
aws iot create-job \
  --job-id "firmware-update-v2.0" \
  --targets "arn:aws:iot:region:account:thinggroup/all-bikes" \
  --document '{
    "operation": "firmware-update",
    "files": [{
      "fileName": "firmware-v2.0.bin",
      "fileSource": {
        "url": "https://ecovolt-prod-firmware.s3.amazonaws.com/bikes/firmware-v2.0.bin"
      }
    }]
  }'
```

## Fleet Query Example

```bash
# Query all connected bikes
aws iot search-index \
  --index-name "AWS_Things" \
  --query-string "thingTypeName:ecovolt-prod-bike AND connectivity.connected:true"

# Query bikes by manufacturer
aws iot search-index \
  --index-name "AWS_Things" \
  --query-string "attributes.manufacturer:EcoVolt"
```

## Security Considerations

- All devices must authenticate using X.509 certificates
- IoT policy enforces least-privilege access (devices can only access their own topics)
- Firmware bucket has public access blocked
- All data in transit uses TLS 1.2+
- CloudTrail logs all IoT API calls
- GuardDuty can be enabled for threat detection

## Cost Optimization

- IoT Core charges per message and connection
- Use message aggregation at edge to reduce message count
- Implement connection pooling for devices
- Use Fleet Indexing selectively (charges per query)
- Set appropriate S3 lifecycle policies for firmware storage

## Troubleshooting

### Device Connection Issues

1. Verify certificate is active and attached to thing
2. Check IoT policy is attached to certificate
3. Verify device is using correct IoT endpoint
4. Check CloudWatch Logs for connection errors
5. Verify network connectivity and firewall rules

### Message Routing Issues

1. Verify IoT Rules are enabled
2. Check Kinesis stream ARN is correct
3. Verify IAM role has permissions to write to Kinesis
4. Check CloudWatch Logs for rule execution errors
5. Test rule with IoT Core test client

### Fleet Indexing Issues

1. Verify Fleet Indexing is enabled
2. Wait for initial indexing to complete (can take several minutes)
3. Check custom fields are configured correctly
4. Verify query syntax is correct
5. Check IAM permissions for SearchIndex API

## References

- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/latest/developerguide/)
- [IoT Device Management](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-management.html)
- [IoT Fleet Indexing](https://docs.aws.amazon.com/iot/latest/developerguide/iot-indexing.html)
- [IoT Jobs](https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html)
