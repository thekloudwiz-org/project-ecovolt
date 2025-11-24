"""
IoT Telemetry Processor Lambda
Processes IoT messages from bikes and stations
"""

import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any
from utils.db import DynamoDBHelper


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Process IoT telemetry messages
    
    Requirements: 13.1, 13.2, 13.3, 13.4, 13.5
    """
    try:
        # Parse IoT message
        message = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event
        
        message_type = message.get('type')
        
        if message_type == 'bike_telemetry':
            return process_bike_telemetry(message)
        elif message_type == 'station_telemetry':
            return process_station_telemetry(message)
        else:
            print(f"Unknown message type: {message_type}")
            return {'statusCode': 400, 'body': json.dumps({'error': 'Unknown message type'})}
            
    except Exception as e:
        print(f"Error processing IoT message: {str(e)}")
        import traceback
        traceback.print_exc()
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}


def process_bike_telemetry(message: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process bike telemetry and update DynamoDB
    
    Requirements: 13.1, 13.2, 13.4, 13.5
    """
    try:
        bike_id = message.get('bike_id')
        telemetry = message.get('telemetry', {})
        
        if not bike_id:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Missing bike_id'})}
        
        # Requirement 13.2: Update bike telemetry in DynamoDB
        telemetry_table = os.getenv('DYNAMODB_TELEMETRY_TABLE', 'ecovolt-dev-vehicle-telemetry')
        
        timestamp = datetime.now()
        
        # Requirement 13.4: Add TTL (30 days)
        ttl = int((timestamp + timedelta(days=30)).timestamp())
        
        item = {
            'bike_id': bike_id,
            'timestamp': timestamp.isoformat(),
            'battery_level': telemetry.get('battery_level', 0),
            'location': telemetry.get('location', {'lat': 0, 'lng': 0}),
            'speed': telemetry.get('speed'),
            'odometer': telemetry.get('odometer'),
            'temperature': telemetry.get('temperature'),
            'ttl': ttl
        }
        
        success = DynamoDBHelper.put_item(
            table_name=telemetry_table,
            item=item
        )
        
        if not success:
            return {'statusCode': 500, 'body': json.dumps({'error': 'Failed to store telemetry'})}
        
        # Requirement 13.5: Trigger low battery alert
        battery_level = telemetry.get('battery_level', 100)
        if battery_level < 10:
            # Get user_id for this bike
            from utils.db import get_db_connection, Queries
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(Queries.GET_BIKE_BY_ID, (bike_id,))
                bike = cursor.fetchone()
                
                if bike and bike.get('user_id'):
                    from utils.notifications import notify_low_battery
                    notify_low_battery(bike['user_id'], bike_id, battery_level)
        
        print(f"Bike telemetry processed: {bike_id}")
        return {'statusCode': 200, 'body': json.dumps({'message': 'Telemetry processed'})}
        
    except Exception as e:
        print(f"Error processing bike telemetry: {str(e)}")
        import traceback
        traceback.print_exc()
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}


def process_station_telemetry(message: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process station telemetry and update DynamoDB
    
    Requirements: 13.1, 13.3, 13.4
    """
    try:
        station_id = message.get('station_id')
        telemetry = message.get('telemetry', {})
        
        if not station_id:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Missing station_id'})}
        
        # Requirement 13.3: Update station telemetry in DynamoDB
        telemetry_table = os.getenv('DYNAMODB_STATION_TELEMETRY_TABLE', 'ecovolt-dev-station-telemetry')
        
        timestamp = datetime.now()
        
        # Requirement 13.4: Add TTL (30 days)
        ttl = int((timestamp + timedelta(days=30)).timestamp())
        
        item = {
            'station_id': station_id,
            'timestamp': timestamp.isoformat(),
            'available_batteries': telemetry.get('available_batteries', 0),
            'energy_consumption': telemetry.get('energy_consumption'),
            'solar_generation': telemetry.get('solar_generation'),
            'temperature': telemetry.get('temperature'),
            'ttl': ttl
        }
        
        success = DynamoDBHelper.put_item(
            table_name=telemetry_table,
            item=item
        )
        
        if not success:
            return {'statusCode': 500, 'body': json.dumps({'error': 'Failed to store telemetry'})}
        
        print(f"Station telemetry processed: {station_id}")
        return {'statusCode': 200, 'body': json.dumps({'message': 'Telemetry processed'})}
        
    except Exception as e:
        print(f"Error processing station telemetry: {str(e)}")
        import traceback
        traceback.print_exc()
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
