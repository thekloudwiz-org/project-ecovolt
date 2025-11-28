"""
Lambda function for processing Kinesis stream data with Fan-Out pattern.
This function implements cost-optimized data routing:
- Current State → DynamoDB (UpdateItem - overwrite)
- Historical Time-Series → InfluxDB (WriteRecords - append)
"""

import json
import os
import base64
import boto3
from datetime import datetime
from decimal import Decimal
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Note: AWS Timestream for InfluxDB uses proper TLS 1.2/1.3 certificates
# SSL verification should be enabled for security

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')

# Environment variables - DynamoDB Current State Tables
BIKE_STATUS_TABLE = os.environ.get('BIKE_STATUS_TABLE', 'ecovolt-dev-bike-status')
STATION_STATUS_TABLE = os.environ.get('STATION_STATUS_TABLE', 'ecovolt-dev-stations')
SWAP_EVENTS_TABLE = os.environ.get('SWAP_EVENTS_TABLE', 'ecovolt-dev-swap-events')

# Environment variables - InfluxDB Historical Storage
INFLUXDB_SECRET_ARN = os.environ.get('INFLUXDB_SECRET_ARN')
INFLUXDB_ENDPOINT = os.environ.get('INFLUXDB_ENDPOINT')
INFLUXDB_ORG = os.environ.get('INFLUXDB_ORG', 'ecovolt')
INFLUXDB_BUCKET = os.environ.get('INFLUXDB_BUCKET', 'dev-telemetry')

# Get DynamoDB tables
bike_status_table = dynamodb.Table(BIKE_STATUS_TABLE)
station_status_table = dynamodb.Table(STATION_STATUS_TABLE)
swap_events_table = dynamodb.Table(SWAP_EVENTS_TABLE)

# InfluxDB client (lazy initialization)
_influxdb_client = None
_influxdb_write_api = None


def get_influxdb_client():
    """Lazy initialization of InfluxDB client."""
    global _influxdb_client, _influxdb_write_api

    if _influxdb_client is None:
        # Get credentials from Secrets Manager
        secret = secretsmanager.get_secret_value(SecretId=INFLUXDB_SECRET_ARN)
        creds = json.loads(secret['SecretString'])

        # AWS Timestream for InfluxDB authentication
        # Use username:password format for basic auth
        print(f"Connecting to InfluxDB: {INFLUXDB_ENDPOINT}")
        print(f"Organization: {INFLUXDB_ORG}")
        print(f"Bucket: {INFLUXDB_BUCKET}")
        print(f"Username: {creds['username']}")

        # AWS Timestream for InfluxDB uses proper TLS certificates
        # SSL verification is enabled for security
        _influxdb_client = InfluxDBClient(
            url=f"https://{INFLUXDB_ENDPOINT}:8086",
            username=creds['username'],
            password=creds['password'],
            org=INFLUXDB_ORG,
            verify_ssl=True,  # Enable SSL verification for security
            timeout=10000  # 10 second timeout
        )
        _influxdb_write_api = _influxdb_client.write_api(write_options=SYNCHRONOUS)

        # Test connection by trying to list buckets
        try:
            buckets_api = _influxdb_client.buckets_api()
            buckets = buckets_api.find_buckets().buckets
            print(f"✅ Successfully connected to InfluxDB. Found {len(buckets)} buckets")
            for bucket in buckets:
                print(f"  - Bucket: {bucket.name} (ID: {bucket.id})")
        except Exception as e:
            print(f"⚠️  Warning: Could not list buckets: {str(e)}")

        print(f"✅ InfluxDB client initialized for org: {INFLUXDB_ORG}, bucket: {INFLUXDB_BUCKET}")

    return _influxdb_client, _influxdb_write_api


def handler(event, context):
    """
    Process Kinesis records with Fan-Out pattern.
    Routes current state to DynamoDB and historical metrics to InfluxDB.
    
    Args:
        event: Kinesis event containing records
        context: Lambda context
        
    Returns:
        dict: Processing results
    """
    records_processed = 0
    records_failed = 0
    
    for record in event['Records']:
        try:
            # Decode Kinesis data
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            data = json.loads(payload)
            
            # Determine message type and route with Fan-Out pattern
            if 'bikeId' in data:
                process_bike_telemetry(data)
            elif 'stationId' in data and 'solar' in data:
                process_station_energy(data)
            elif 'swapId' in data:
                write_swap_event(data)
            else:
                print(f"Unknown message type: {data}")
                records_failed += 1
                continue
                
            records_processed += 1
            
        except Exception as e:
            print(f"Error processing record: {str(e)}")
            print(f"Record data: {record}")
            import traceback
            traceback.print_exc()
            records_failed += 1
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'recordsProcessed': records_processed,
            'recordsFailed': records_failed
        })
    }


def convert_floats_to_decimal(obj):
    """Convert float values to Decimal for DynamoDB compatibility."""
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimal(item) for item in obj]
    return obj


def process_bike_telemetry(data):
    """
    Fan-Out Pattern: Split bike telemetry into current state and historical metrics.
    
    Target A (DynamoDB): Current state only - UpdateItem (overwrite)
    Target B (InfluxDB): Historical time-series - WriteRecords (append)
    """
    bike_id = data['bikeId']
    timestamp = datetime.now()
    
    # ============================================================================
    # TARGET A: DynamoDB - Current State Only (UpdateItem - NO history)
    # ============================================================================
    battery = data.get('battery', {})
    location = data.get('location', {})
    
    current_state = {
        'bikeId': bike_id,
        'status': data.get('status', 'active'),  # charging, idle, riding
        'currentSOC': convert_floats_to_decimal(battery.get('level', 0)),
        'gpsLat': convert_floats_to_decimal(location.get('lat', 0)),
        'gpsLon': convert_floats_to_decimal(location.get('lon', 0)),
        'lastSeen': int(timestamp.timestamp()),
        'lastUpdated': int(timestamp.timestamp()),  # Required for UserBikesIndex GSI
        'speed': convert_floats_to_decimal(data.get('speed', 0)),
        'odometer': data.get('odometer', 0),
        'userId': data.get('userId', 'unassigned')  # Use placeholder for GSI compatibility
    }
    
    # Use UpdateItem to OVERWRITE current state (not create new rows)
    bike_status_table.put_item(Item=current_state)
    print(f"✅ Updated current state for bike {bike_id}")
    
    # ============================================================================
    # TARGET B: InfluxDB - Historical Time-Series Metrics (append-only)
    # ============================================================================
    try:
        _, write_api = get_influxdb_client()
        
        # Write voltage time-series
        if 'voltage' in battery:
            point = Point("bike_voltage") \
                .tag("bikeId", bike_id) \
                .field("value", float(battery['voltage'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write current time-series
        if 'current' in battery:
            point = Point("bike_current") \
                .tag("bikeId", bike_id) \
                .field("value", float(battery['current'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write temperature time-series
        if 'temperature' in battery:
            point = Point("bike_temperature") \
                .tag("bikeId", bike_id) \
                .field("value", float(battery['temperature'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write power output time-series
        if 'power' in data:
            point = Point("bike_power") \
                .tag("bikeId", bike_id) \
                .field("value", float(data['power'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        print(f"✅ Wrote historical metrics to InfluxDB for bike {bike_id}")

    except Exception as e:
        print(f"⚠️  Failed to write to InfluxDB for bike {bike_id}")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        import traceback
        traceback.print_exc()
        # Don't fail the entire record if InfluxDB write fails


def process_station_energy(data):
    """
    Fan-Out Pattern: Split station energy into current state and historical metrics.
    
    Target A (DynamoDB): Current state only - UpdateItem (overwrite)
    Target B (InfluxDB): Historical time-series - WriteRecords (append)
    """
    station_id = data['stationId']
    timestamp = datetime.now()
    
    # ============================================================================
    # TARGET A: DynamoDB - Current State Only (UpdateItem - NO history)
    # ============================================================================
    solar = data.get('solar', {})
    grid = data.get('grid', {})
    inventory = data.get('inventory', {})
    
    current_state = {
        'stationId': station_id,
        'status': data.get('status', 'active'),
        'availableBatteries': inventory.get('available', 0),
        'chargingBatteries': inventory.get('charging', 0),
        'currentSolarPower': convert_floats_to_decimal(solar.get('power', 0)),
        'currentGridPower': convert_floats_to_decimal(grid.get('power', 0)),
        'lastSeen': int(timestamp.timestamp())
    }
    
    # Use UpdateItem to OVERWRITE current state
    station_status_table.update_item(
        Key={'stationId': station_id},
        UpdateExpression='SET #status = :status, availableBatteries = :avail, chargingBatteries = :charging, currentSolarPower = :solar, currentGridPower = :grid, lastSeen = :seen',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': current_state['status'],
            ':avail': current_state['availableBatteries'],
            ':charging': current_state['chargingBatteries'],
            ':solar': current_state['currentSolarPower'],
            ':grid': current_state['currentGridPower'],
            ':seen': current_state['lastSeen']
        }
    )
    print(f"✅ Updated current state for station {station_id}")
    
    # ============================================================================
    # TARGET B: InfluxDB - Historical Time-Series Metrics (append-only)
    # ============================================================================
    try:
        _, write_api = get_influxdb_client()
        
        # Write solar generation time-series
        if 'generation' in solar:
            point = Point("station_solar_generation") \
                .tag("stationId", station_id) \
                .field("value", float(solar['generation'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write solar power time-series
        if 'power' in solar:
            point = Point("station_solar_power") \
                .tag("stationId", station_id) \
                .field("value", float(solar['power'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write grid consumption time-series
        if 'consumption' in grid:
            point = Point("station_grid_consumption") \
                .tag("stationId", station_id) \
                .field("value", float(grid['consumption'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        # Write energy cost time-series
        if 'cost' in grid:
            point = Point("station_energy_cost") \
                .tag("stationId", station_id) \
                .field("value", float(grid['cost'])) \
                .time(timestamp)
            write_api.write(bucket=INFLUXDB_BUCKET, record=point)
        
        print(f"✅ Wrote historical metrics to InfluxDB for station {station_id}")

    except Exception as e:
        print(f"⚠️  Failed to write to InfluxDB for station {station_id}")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        import traceback
        traceback.print_exc()
        # Don't fail the entire record if InfluxDB write fails


def write_swap_event(data):
    """Write swap event to DynamoDB."""
    # Get timestamp (milliseconds)
    if 'timestamp' in data:
        timestamp = int(datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00')).timestamp() * 1000)
    else:
        timestamp = int(datetime.now().timestamp() * 1000)

    # Calculate TTL (90 days from now)
    ttl = int((datetime.now().timestamp() + (90 * 24 * 60 * 60)))

    # Prepare item for DynamoDB
    item = {
        'swapId': data['swapId'],
        'timestamp': timestamp,
        'ttl': ttl,
        'bikeId': data.get('bikeId', ''),
        'stationId': data.get('stationId', ''),
        'userId': data.get('userId', ''),
        'removedBatteryId': data.get('removedBatteryId', ''),
        'installedBatteryId': data.get('installedBatteryId', ''),
        'duration': data.get('duration', 0),
        'cost': convert_floats_to_decimal(data.get('cost', 0)),
        'paymentMethod': data.get('paymentMethod', ''),
        'recordedAt': data.get('timestamp', datetime.now().isoformat())
    }

    # Write to DynamoDB
    swap_events_table.put_item(Item=item)
    print(f"Wrote swap event {data['swapId']} at {timestamp}")
