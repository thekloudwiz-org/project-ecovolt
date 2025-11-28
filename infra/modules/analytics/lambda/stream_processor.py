"""
Lambda function for processing Kinesis stream data and writing to DynamoDB.
This function consumes telemetry data from Kinesis and writes it to appropriate DynamoDB tables.
"""

import json
import os
import base64
import boto3
from datetime import datetime
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Environment variables
BIKE_TELEMETRY_TABLE = os.environ.get('BIKE_TELEMETRY_TABLE', 'ecovolt-dev-bike-telemetry')
STATION_ENERGY_TABLE = os.environ.get('STATION_ENERGY_TABLE', 'ecovolt-dev-station-energy')
SWAP_EVENTS_TABLE = os.environ.get('SWAP_EVENTS_TABLE', 'ecovolt-dev-swap-events')

# Get DynamoDB tables
bike_telemetry_table = dynamodb.Table(BIKE_TELEMETRY_TABLE)
station_energy_table = dynamodb.Table(STATION_ENERGY_TABLE)
swap_events_table = dynamodb.Table(SWAP_EVENTS_TABLE)


def handler(event, context):
    """
    Process Kinesis records and write to Timestream.
    
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
            
            # Determine message type and route to appropriate table
            if 'bikeId' in data:
                write_bike_telemetry(data)
            elif 'stationId' in data and 'solar' in data:
                write_station_energy(data)
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


def write_bike_telemetry(data):
    """Write bike telemetry to DynamoDB."""
    # Get timestamp (milliseconds)
    if 'timestamp' in data:
        timestamp = int(datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00')).timestamp() * 1000)
    else:
        timestamp = int(datetime.now().timestamp() * 1000)

    # Calculate TTL (90 days from now)
    ttl = int((datetime.now().timestamp() + (90 * 24 * 60 * 60)))

    # Prepare item for DynamoDB
    item = {
        'bikeId': data['bikeId'],
        'timestamp': timestamp,
        'ttl': ttl,
        'battery': convert_floats_to_decimal(data.get('battery', {})),
        'location': convert_floats_to_decimal(data.get('location', {})),
        'speed': convert_floats_to_decimal(data.get('speed', 0)),
        'odometer': data.get('odometer', 0),
        'recordedAt': data.get('timestamp', datetime.now().isoformat())
    }

    # Write to DynamoDB
    bike_telemetry_table.put_item(Item=item)
    print(f"Wrote bike telemetry for {data['bikeId']} at {timestamp}")


def write_station_energy(data):
    """Write station energy data to DynamoDB."""
    # Get timestamp (milliseconds)
    if 'timestamp' in data:
        timestamp = int(datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00')).timestamp() * 1000)
    else:
        timestamp = int(datetime.now().timestamp() * 1000)

    # Calculate TTL (90 days from now)
    ttl = int((datetime.now().timestamp() + (90 * 24 * 60 * 60)))

    # Prepare item for DynamoDB
    item = {
        'stationId': data['stationId'],
        'timestamp': timestamp,
        'ttl': ttl,
        'solar': convert_floats_to_decimal(data.get('solar', {})),
        'grid': convert_floats_to_decimal(data.get('grid', {})),
        'inventory': convert_floats_to_decimal(data.get('inventory', {})),
        'recordedAt': data.get('timestamp', datetime.now().isoformat())
    }

    # Write to DynamoDB
    station_energy_table.put_item(Item=item)
    print(f"Wrote station energy for {data['stationId']} at {timestamp}")


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
