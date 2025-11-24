# Monitoring Module

This module creates CloudWatch alarms, SNS topics, and dashboards for comprehensive monitoring of the EcoVolt AWS Infrastructure.

## Features

- **SNS Topics**: Email and SMS notifications for alarms
- **Lambda Alarms**: Errors, duration, throttles, concurrent executions
- **API Gateway Alarms**: 4xx/5xx errors, latency
- **Database Alarms**: CPU, connections, storage
- **Kinesis Alarms**: Iterator age, throttling
- **CloudWatch Dashboard**: System overview with key metrics

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "ecovolt"
  environment  = "prod"

  # Notification configuration
  alarm_email_addresses = ["thekloudwiz+ecovolt@gmail.com", "thekloudwiz+ecovolt@gmail.com"]
  alarm_phone_numbers   = ["+233549379885"]

  # Lambda monitoring
  lambda_function_names = [
    module.compute.api_handler_function_name,
    module.compute.stream_processor_function_name
  ]

  # API Gateway monitoring
  api_gateway_id         = module.compute.api_gateway_id
  api_gateway_stage_name = module.compute.api_gateway_stage_name

  # Database monitoring
  db_instance_id = module.database.db_instance_id

  # Kinesis monitoring
  kinesis_stream_name = module.analytics.kinesis_stream_name

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
```

## Alarms

### Lambda Alarms
- **Errors**: Triggers when error count exceeds threshold
- **Duration**: Triggers when execution time exceeds threshold
- **Throttles**: Triggers immediately on any throttling

### API Gateway Alarms
- **4xx Errors**: Client errors exceeding threshold
- **5xx Errors**: Server errors exceeding threshold (critical)
- **Latency**: Response time exceeding threshold

### Database Alarms
- **CPU**: CPU utilization exceeding threshold
- **Connections**: Connection count exceeding threshold
- **Storage**: Free storage below threshold (critical)

### Kinesis Alarms
- **Iterator Age**: Processing lag exceeding threshold

## Dashboard

The CloudWatch dashboard provides real-time visibility into:
- Lambda invocations and errors
- API Gateway requests and errors
- Database CPU and connections
- Kinesis processing metrics

## Notification Channels

- **Email**: General and critical alarms
- **SMS**: Critical alarms only (requires phone number confirmation)

## Properties Validated

- **Property 24**: Comprehensive metric collection (Requirements 8.1)
- **Property 25**: Threshold-based alerting (Requirements 8.2)
- **Property 26**: Centralized log aggregation (Requirements 8.3)
- **Property 27**: Critical failure notification timing (Requirements 8.5)

## References

- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [SNS Notifications](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
