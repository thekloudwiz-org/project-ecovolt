# DynamoDB Module

This module creates Amazon DynamoDB tables for operational data storage in the EcoVolt application.

## Data Architecture

**DynamoDB**: Operational data (stations, users, last known status)  
**Timestream**: High-frequency metrics (battery %, voltage, current, power, temperature)

## Tables

### 1. Stations Table
Stores EV charging/swap station information.

**Schema**:
```
stationId (PK)          # Station identifier
name                    # Station name
location                # "lat,lon" format
address                 # Physical address
capacity                # Number of battery slots
status                  # active, maintenance, offline
solarCapacity           # Solar panel capacity (kW)
gridConnection          # Grid connection status
operatingHours          # Operating hours
contactInfo             # Contact information
createdAt               # Creation timestamp
updatedAt               # Last update timestamp
```

**GSIs**:
- `LocationIndex`: Query stations by location
- `StatusIndex`: Query stations by status

**Use Cases**:
- Find nearest stations
- Check station availability
- Monitor station status
- Station management

### 2. User Profiles Table
Stores user account information.

**Schema**:
```
userId (PK)             # Cognito sub (UUID)
email                   # User email
name                    # Full name
phoneNumber             # Phone number
bikeIds              # List of owned bike IDs
paymentMethods          # Payment method info
preferences             # User preferences
createdAt               # Account creation timestamp
updatedAt               # Last update timestamp
lastLoginAt             # Last login timestamp
```

**GSIs**:
- `EmailIndex`: Query users by email
- `CreatedAtIndex`: Query users by registration date

**Use Cases**:
- User authentication
- Profile management
- bike ownership tracking
- Payment processing

### 3. bike Status Table
Stores last known status of each bike.

**Schema**:
```
bikeId (PK)          # bike identifier
userId                  # Owner user ID
model                   # bike model
vin                     # bike identification number
batteryId               # Current battery ID
batteryLevel            # Current battery level (0-100)
location                # Last known location
status                  # active, charging, swapping, parked, offline
odometer                # Odometer reading
lastUpdated             # Last status update timestamp
ttl                     # TTL for old records (optional)
```

**GSIs**:
- `UserbikesIndex`: Query bikes by user
- `BatteryLevelIndex`: Query bikes by battery level (for low battery alerts)

**Use Cases**:
- bike tracking
- Battery level monitoring
- Low battery alerts
- bike-user association

### 4. Battery Inventory Table
Stores battery inventory at each station.

**Schema**:
```
batteryId (PK)          # Battery identifier
stationId               # Current station location
status                  # available, charging, swapping, maintenance, retired
stateOfCharge           # Current charge level (0-100)
health                  # Battery health (0-100)
cycleCount              # Number of charge cycles
manufacturer            # Battery manufacturer
model                   # Battery model
capacity                # Battery capacity (kWh)
lastSwapAt              # Last swap timestamp
lastChargeAt            # Last charge timestamp
createdAt               # Battery creation timestamp
```

**GSIs**:
- `StationBatteriesIndex`: Query batteries by station and status
- `AvailableBatteriesIndex`: Query available batteries by charge level

**Use Cases**:
- Battery availability checking
- Inventory management
- Battery health monitoring
- Swap optimization

### 5. Swap Events Table
Stores battery swap transaction history.

**Schema**:
```
swapId (PK)             # Swap event UUID
timestamp (SK)          # Swap timestamp
bikeId               # bike ID
stationId               # Station ID
userId                  # User ID
removedBatteryId        # Battery removed from bike
installedBatteryId      # Battery installed in bike
duration                # Swap duration (seconds)
cost                    # Swap cost
paymentMethod           # Payment method used
ttl                     # TTL for old records (90 days)
```

**GSIs**:
- `bikeSwapsIndex`: Query swaps by bike
- `StationSwapsIndex`: Query swaps by station
- `UserSwapsIndex`: Query swaps by user

**Use Cases**:
- Swap history
- Billing and invoicing
- Station performance analytics
- User activity tracking

## Usage

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = "ecovolt"
  environment  = "prod"

  # Billing mode
  billing_mode = "PAY_PER_REQUEST" # or "PROVISIONED"

  # Encryption
  kms_key_arn = module.security.kms_key_arn

  # Backup
  enable_point_in_time_recovery = true

  # TTL
  enable_bike_status_ttl = false
  enable_swap_events_ttl    = true

  # Monitoring
  alarm_sns_topic_arns = [module.monitoring.sns_topic_arn]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Billing Modes

### PAY_PER_REQUEST (On-Demand)
**Recommended for**: Development, staging, unpredictable workloads

**Pricing**:
- $1.25 per million write requests
- $0.25 per million read requests
- No minimum capacity

**Pros**:
- No capacity planning
- Automatic scaling
- Pay only for what you use

**Cons**:
- Higher cost at scale
- No reserved capacity discounts

### PROVISIONED
**Recommended for**: Production with predictable traffic

**Pricing**:
- $0.00065 per WCU-hour
- $0.00013 per RCU-hour
- Reserved capacity available

**Pros**:
- Lower cost at scale
- Predictable billing
- Reserved capacity discounts

**Cons**:
- Requires capacity planning
- Manual scaling (or auto-scaling)
- Throttling if exceeded

## Capacity Planning

### Estimating Capacity

**Write Capacity Units (WCU)**:
- 1 WCU = 1 write/sec for items up to 1 KB
- Example: 100 writes/sec of 2 KB items = 200 WCU

**Read Capacity Units (RCU)**:
- 1 RCU = 1 strongly consistent read/sec for items up to 4 KB
- 1 RCU = 2 eventually consistent reads/sec for items up to 4 KB
- Example: 100 reads/sec of 4 KB items = 100 RCU (strongly consistent)

### Recommended Capacity (Provisioned Mode)

**Development**:
- Tables: 5 RCU / 5 WCU
- GSIs: 5 RCU / 5 WCU

**Staging**:
- Tables: 10 RCU / 10 WCU
- GSIs: 5 RCU / 5 WCU

**Production**:
- Stations: 20 RCU / 10 WCU
- Users: 50 RCU / 20 WCU
- bike Status: 100 RCU / 50 WCU
- Battery Inventory: 50 RCU / 20 WCU
- Swap Events: 20 RCU / 50 WCU

## Auto-Scaling

Enable auto-scaling for provisioned capacity:

```hcl
billing_mode       = "PROVISIONED"
enable_autoscaling = true

stations_read_capacity  = 10  # Minimum
stations_write_capacity = 10  # Minimum

autoscaling_max_read_capacity  = 100  # Maximum
autoscaling_max_write_capacity = 100  # Maximum
```

Auto-scaling triggers at 70% utilization.

## Data Lifecycle

### TTL (Time To Live)

**bike Status**: Optional TTL
- Keep only recent status (e.g., 30 days)
- Historical data in Timestream

**Swap Events**: TTL enabled (90 days)
- Keep recent transactions
- Archive to S3 for long-term storage

### Point-in-Time Recovery

Enabled by default for all tables. Allows recovery to any point in the last 35 days.

## Streams

All tables have DynamoDB Streams enabled for:
- Real-time data processing
- Change data capture (CDC)
- Replication to other systems
- Audit logging

Stream view type: `NEW_AND_OLD_IMAGES` (full item before and after)

## Access Patterns

### Stations
- Get station by ID: `GetItem(stationId)`
- Find stations by location: `Query(LocationIndex)`
- List active stations: `Query(StatusIndex, status=active)`

### User Profiles
- Get user by ID: `GetItem(userId)`
- Find user by email: `Query(EmailIndex, email=...)`
- List recent users: `Query(CreatedAtIndex)`

### bike Status
- Get bike status: `GetItem(bikeId)`
- List user's bikes: `Query(UserbikesIndex, userId=...)`
- Find low battery bikes: `Query(BatteryLevelIndex, batteryLevel<20)`

### Battery Inventory
- Get battery info: `GetItem(batteryId)`
- List station batteries: `Query(StationBatteriesIndex, stationId=...)`
- Find available batteries: `Query(AvailableBatteriesIndex, status=available)`

### Swap Events
- Get swap details: `GetItem(swapId)`
- List bike swaps: `Query(bikeSwapsIndex, bikeId=...)`
- List station swaps: `Query(StationSwapsIndex, stationId=...)`
- List user swaps: `Query(UserSwapsIndex, userId=...)`

## Cost Estimation

### On-Demand (PAY_PER_REQUEST)

**Assumptions**:
- 1,000 stations
- 10,000 users
- 5,000 bikes
- 10,000 batteries
- 1,000 swaps/day

**Monthly Costs**:
- Stations: ~$5 (low write volume)
- Users: ~$10 (moderate read/write)
- bike Status: ~$50 (high write volume)
- Battery Inventory: ~$20 (moderate read/write)
- Swap Events: ~$30 (moderate write volume)
- **Total**: ~$115/month

### Provisioned Capacity

**Production Configuration**:
- Total RCU: 240 (across all tables)
- Total WCU: 150 (across all tables)

**Monthly Costs**:
- RCU: 240 × $0.00013 × 730 hours = ~$23
- WCU: 150 × $0.00065 × 730 hours = ~$71
- **Total**: ~$94/month

**Savings**: ~18% with provisioned capacity

## Monitoring

### CloudWatch Metrics
- `ConsumedReadCapacityUnits`: Read capacity consumed
- `ConsumedWriteCapacityUnits`: Write capacity consumed
- `ReadThrottleEvents`: Read requests throttled
- `WriteThrottleEvents`: Write requests throttled
- `UserErrors`: Client-side errors
- `SystemErrors`: Server-side errors

### CloudWatch Alarms
- Read throttle events > 10 in 5 minutes
- Write throttle events > 10 in 5 minutes
- System errors > 5 in 5 minutes

## Best Practices

1. **Use On-Demand for Development**: Simplifies capacity planning
2. **Enable Point-in-Time Recovery**: For production tables
3. **Use TTL for Transient Data**: Automatic cleanup
4. **Monitor Throttling**: Adjust capacity if throttled
5. **Use GSIs Wisely**: Each GSI doubles storage cost
6. **Batch Operations**: Use BatchGetItem/BatchWriteItem
7. **Consistent Reads**: Use eventually consistent reads when possible
8. **Item Size**: Keep items under 4 KB for optimal performance
9. **Partition Key Design**: Ensure even distribution
10. **Backup Strategy**: Regular backups to S3

## Integration with Lambda

```python
import boto3

dynamodb = boto3.resource('dynamodb')
stations_table = dynamodb.Table('ecovolt-prod-stations')

# Get station
response = stations_table.get_item(Key={'stationId': 'station-123'})
station = response['Item']

# Query by location
response = stations_table.query(
    IndexName='LocationIndex',
    KeyConditionExpression='location = :loc',
    ExpressionAttributeValues={':loc': '37.7749,-122.4194'}
)
stations = response['Items']
```

## References

- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/)
