# Compute Module

This module creates and manages serverless compute resources for the EcoVolt AWS Infrastructure, including:
- AWS Lambda functions for backend API operations
- AWS Lambda functions for stream processing
- Amazon API Gateway for RESTful API endpoints
- Security groups for Lambda VPC access
- CloudWatch Logs for monitoring and debugging

## Features

### Lambda Functions
- **API Handler**: Processes backend API requests (CRUD operations for bikes, stations, swaps)
- **Stream Processor**: Processes Kinesis stream data for real-time telemetry
- **VPC Integration**: Lambda functions deployed in private subnets with secure database access
- **Auto-scaling**: Automatic concurrency scaling based on request load
- **X-Ray Tracing**: Distributed tracing for performance analysis
- **Reserved Concurrency**: Optional reserved capacity for critical functions

### API Gateway
- **RESTful API**: HTTP API endpoints for backend operations
- **Request Validation**: Input validation and transformation
- **Throttling**: Rate limiting and burst protection
- **Access Logs**: Detailed request/response logging
- **CORS Support**: Cross-origin resource sharing enabled
- **Regional Endpoint**: Low-latency regional deployment

### Security
- **VPC Isolation**: Lambda functions run in private subnets
- **Security Groups**: Least-privilege network access
- **IAM Roles**: Fine-grained permissions for each function
- **API Gateway Authorization**: Support for API keys and IAM auth

## Usage

```hcl
module "compute" {
  source = "./modules/compute"

  project_name = "ecovolt"
  environment  = "prod"

  # Network configuration
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids

  # Database configuration (optional)
  db_endpoint          = module.database.db_endpoint
  db_name              = module.database.db_name
  db_security_group_id = module.database.db_security_group_id

  # Kinesis configuration (optional)
  kinesis_stream_arn = module.analytics.kinesis_stream_arn

  # Lambda configuration
  lambda_runtime      = "python3.11"
  lambda_memory_size  = 512
  lambda_timeout      = 30
  enable_xray_tracing = true

  # API Gateway configuration
  api_gateway_name                = "ecovolt-api"
  api_gateway_stage_name          = "v1"
  api_gateway_throttle_rate_limit = 10000
  enable_api_gateway_access_logs  = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| archive | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Project name used in resource naming | `string` | `"ecovolt"` | no |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID for Lambda security groups | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| lambda_runtime | Lambda runtime environment | `string` | `"python3.11"` | no |
| lambda_memory_size | Memory size for Lambda functions in MB | `number` | `256` | no |
| lambda_timeout | Timeout for Lambda functions in seconds | `number` | `30` | no |
| enable_xray_tracing | Enable AWS X-Ray tracing | `bool` | `true` | no |
| api_gateway_name | Name for API Gateway REST API | `string` | `"ecovolt-api"` | no |
| api_gateway_throttle_rate_limit | Throttle rate limit (requests/sec) | `number` | `10000` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_gateway_invoke_url | API Gateway invoke URL |
| api_gateway_id | API Gateway REST API ID |
| api_handler_function_arn | API handler Lambda function ARN |
| lambda_execution_role_arn | Lambda execution IAM role ARN |
| lambda_security_group_id | Lambda security group ID |

## Lambda Functions

### API Handler
Handles backend API operations including:
- **GET /health**: Health check endpoint
- **GET /bikes**: List bikes
- **POST /bikes**: Create bike
- **GET /stations**: List stations
- **POST /stations**: Create station
- **GET /swaps**: List swap events
- **POST /swaps**: Create swap event

### Stream Processor
Processes Kinesis stream records for:
- Real-time telemetry data processing
- Data validation and transformation
- Database updates
- Alert triggering

## Auto-Scaling

Lambda functions automatically scale based on:
- **Concurrent Executions**: Scales up to account limits
- **Reserved Concurrency**: Optional reserved capacity for critical functions
- **Burst Capacity**: Handles traffic spikes automatically

**Property 16: Auto-scaling on load increase** - Validates Requirements 4.2

## Request Distribution

API Gateway distributes requests across Lambda function instances:
- **Round-robin distribution**: Even load distribution
- **Automatic scaling**: New instances created as needed
- **Throttling**: Rate limiting prevents overload

**Property 17: Request distribution across functions** - Validates Requirements 4.3

## Error Handling

Lambda functions implement comprehensive error handling:
- **Automatic Retries**: Exponential backoff for transient errors
- **Dead Letter Queues**: Failed events sent to DLQ (optional)
- **CloudWatch Alarms**: Alerts on error thresholds
- **X-Ray Tracing**: Detailed error analysis

**Property 18: Function error handling and retry** - Validates Requirements 4.4

## API Gateway Endpoints

### Health Check
```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "service": "ecovolt-api",
  "version": "1.0.0"
}
```

### bikes
```bash
# List bikes
GET /bikes

# Create bike
POST /bikes
{
  "model": "EcoVolt E-Bike",
  "vin": "1HGBH41JXMN109186"
}
```

### Stations
```bash
# List stations
GET /stations

# Create station
POST /stations
{
  "name": "Downtown Station",
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

### Swaps
```bash
# List swaps
GET /swaps

# Create swap
POST /swaps
{
  "station_id": "station-123",
  "bike_id": "bike-456",
  "removed_battery_id": "battery-789",
  "installed_battery_id": "battery-012"
}
```

## Monitoring

### CloudWatch Logs
- Lambda function logs: `/aws/lambda/{function-name}`
- API Gateway logs: `/aws/apigateway/{api-name}`
- Retention: Configurable (default 30 days)

### CloudWatch Metrics
- Lambda invocations, errors, duration, throttles
- API Gateway requests, 4xx/5xx errors, latency
- Custom metrics for business KPIs

### X-Ray Tracing
- End-to-end request tracing
- Service map visualization
- Performance bottleneck identification
- Error analysis

## Security Best Practices

1. **VPC Isolation**: Lambda functions run in private subnets
2. **Least Privilege**: IAM roles grant minimum required permissions
3. **Security Groups**: Network access restricted to required resources
4. **API Gateway**: Support for API keys, IAM authorization, and throttling
5. **Encryption**: All data encrypted in transit (TLS 1.2+)
6. **Secrets Management**: Use AWS Secrets Manager for sensitive data

## Performance Optimization

### Lambda Configuration
- **Memory**: Higher memory = more CPU (128 MB - 10240 MB)
- **Timeout**: Set based on expected execution time (1-900 seconds)
- **Reserved Concurrency**: Guarantee capacity for critical functions
- **Provisioned Concurrency**: Pre-warm instances for low latency

### API Gateway
- **Caching**: Enable response caching for read-heavy endpoints
- **Throttling**: Protect backend from overload
- **Regional Endpoint**: Deploy close to users for low latency

## Cost Optimization

- Use appropriate Lambda memory sizes (don't over-provision)
- Set reasonable timeouts to avoid long-running functions
- Enable API Gateway caching to reduce Lambda invocations
- Use reserved concurrency only when necessary
- Monitor CloudWatch Logs retention to control storage costs

## Troubleshooting

### Lambda Function Errors
- Check CloudWatch Logs for error messages
- Use X-Ray to trace request flow
- Verify IAM permissions
- Check VPC configuration and security groups

### API Gateway Issues
- Verify Lambda integration configuration
- Check API Gateway logs for request/response details
- Test Lambda function directly (bypass API Gateway)
- Verify CORS configuration for browser requests

### VPC Connectivity
- Ensure Lambda has ENI in private subnets
- Verify security group rules allow required traffic
- Check NAT Gateway for internet access (if needed)
- Verify database security group allows Lambda access

## Example: Invoking API

```bash
# Health check
curl https://api-id.execute-api.region.amazonaws.com/v1/health

# Create bike
curl -X POST https://api-id.execute-api.region.amazonaws.com/v1/bikes \
  -H "Content-Type: application/json" \
  -d '{
    "model": "EcoVolt E-Bike",
    "vin": "1HGBH41JXMN109186"
  }'
```

## Example: Lambda Function with Database

```python
import psycopg2
import os

def lambda_handler(event, context):
    # Get database connection from environment
    conn = psycopg2.connect(
        host=os.environ['DB_ENDPOINT'].split(':')[0],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )
    
    # Execute query
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM bikes")
    results = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return {
        'statusCode': 200,
        'body': json.dumps({'bikes': results})
    }
```

## Future Enhancements

- **GraphQL API**: Add AWS AppSync for GraphQL support
- **WebSocket API**: Real-time bidirectional communication
- **Step Functions**: Orchestrate complex workflows
- **Lambda Layers**: Share common code across functions
- **Provisioned Concurrency**: Pre-warm instances for consistent latency
- **API Gateway Custom Domains**: Use custom domain names
- **WAF Integration**: Add AWS WAF for API protection

## References

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
