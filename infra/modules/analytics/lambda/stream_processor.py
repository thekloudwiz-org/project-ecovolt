"""
Lambda function for processing Kinesis stream data and writing to Timestream.
This function consumes telemetry data from Kinesis and writes it to appropriate Timestream tables.
"""

import json
import os
import base64
import boto3
from datetime import datetime

# Initialize Timestream client
timestream_write = boto3.client('timestream-write')

# Environment variables
TIMESTREAM_DATABASE = os.environ['TIMESTREAM_DATABASE']
BIKE_TABLE = os.environ['BIKE_TABLE']
STATION_TABLE = os.environ['STATION_TABLE']
SWAP_TABLE = os.environ['SWAP_TABLE']


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


def write_bike_telemetry(data):
    """Write bike telemetry to Timestream."""
    current_time = str(int(datetime.now().timestamp() * 1000))
    
    records = [
        {
            'Dimensions': [
                {'Name': 'bikeId', 'Value': data['bikeId']},
                {'Name': 'type', 'Value': 'telemetry'}
            ],
            'MeasureName': 'battery_soc',
            'MeasureValue': str(data['battery']['stateOfCharge']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        },
        {
            'Dimensions': [
                {'Name': 'bikeId', 'Value': data['bikeId']},
                {'Name': 'type', 'Value': 'telemetry'}
            ],
            'MeasureName': 'battery_voltage',
            'MeasureValue': str(data['battery']['voltage']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        },
        {
            'Dimensions': [
                {'Name': 'bikeId', 'Value': data['bikeId']},
                {'Name': 'type', 'Value': 'telemetry'}
            ],
            'MeasureName': 'speed',
            'MeasureValue': str(data['speed']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        }
    ]
    
    timestream_write.write_records(
        DatabaseName=TIMESTREAM_DATABASE,
        TableName=BIKE_TABLE,
        Records=records
    )


def write_station_energy(data):
    """Write station energy data to Timestream."""
    current_time = str(int(datetime.now().timestamp() * 1000))
    
    records = [
        {
            'Dimensions': [
                {'Name': 'stationId', 'Value': data['stationId']},
                {'Name': 'type', 'Value': 'energy'}
            ],
            'MeasureName': 'solar_power',
            'MeasureValue': str(data['solar']['powerGenerated']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        },
        {
            'Dimensions': [
                {'Name': 'stationId', 'Value': data['stationId']},
                {'Name': 'type', 'Value': 'energy'}
            ],
            'MeasureName': 'grid_consumed',
            'MeasureValue': str(data['grid']['powerConsumed']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        }
    ]
    
    timestream_write.write_records(
        DatabaseName=TIMESTREAM_DATABASE,
        TableName=STATION_TABLE,
        Records=records
    )


def write_swap_event(data):
    """Write swap event to Timestream."""
    current_time = str(int(datetime.now().timestamp() * 1000))
    
    records = [
        {
            'Dimensions': [
                {'Name': 'swapId', 'Value': data['swapId']},
                {'Name': 'stationId', 'Value': data['stationId']},
                {'Name': 'bikeId', 'Value': data['bikeId']},
                {'Name': 'type', 'Value': 'swap'}
            ],
            'MeasureName': 'duration',
            'MeasureValue': str(data['duration']),
            'MeasureValueType': 'BIGINT',
            'Time': current_time
        }
    ]
    
    timestream_write.write_records(
        DatabaseName=TIMESTREAM_DATABASE,
        TableName=SWAP_TABLE,
        Records=records
    )
