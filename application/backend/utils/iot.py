"""
IoT Utilities Module
Handles IoT Core integration for bikes and stations
"""

import os
import json
import boto3
from typing import Dict, Any, Optional
from datetime import datetime
from utils.db import DynamoDBHelper

# AWS clients
iot_client = boto3.client('iot-data')


def send_command_to_station(station_id: str, command: Dict[str, Any]) -> bool:
    """
    Send command to station via IoT Core
    
    Requirements: 13.1
    """
    try:
        topic = f"ecovolt/stations/{station_id}/commands"
        
        payload = {
            'command': command,
            'timestamp': datetime.now().isoformat()
        }
        
        iot_client.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(payload)
        )
        
        print(f"Command sent to station {station_id}")
        return True
        
    except Exception as e:
        print(f"Error sending command to station: {str(e)}")
        return False


def send_command_to_bike(bike_id: str, command: Dict[str, Any]) -> bool:
    """
    Send command to bike via IoT Core
    
    Requirements: 13.2
    """
    try:
        topic = f"ecovolt/bikes/{bike_id}/commands"
        
        payload = {
            'command': command,
            'timestamp': datetime.now().isoformat()
        }
        
        iot_client.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(payload)
        )
        
        print(f"Command sent to bike {bike_id}")
        return True
        
    except Exception as e:
        print(f"Error sending command to bike: {str(e)}")
        return False


def get_latest_bike_telemetry(bike_id: str) -> Optional[Dict[str, Any]]:
    """
    Query latest telemetry for a bike from DynamoDB
    
    Requirements: 13.3
    """
    try:
        telemetry_table = os.getenv('DYNAMODB_TELEMETRY_TABLE', 'ecovolt-dev-vehicle-telemetry')
        
        telemetry_items = DynamoDBHelper.query(
            table_name=telemetry_table,
            key_condition='bike_id = :bike_id',
            expression_values={':bike_id': bike_id}
        )
        
        if not telemetry_items:
            return None
        
        # Sort by timestamp and get latest
        telemetry_items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return telemetry_items[0]
        
    except Exception as e:
        print(f"Error getting bike telemetry: {str(e)}")
        return None


def get_latest_station_telemetry(station_id: str) -> Optional[Dict[str, Any]]:
    """
    Query latest telemetry for a station from DynamoDB
    
    Requirements: 13.3
    """
    try:
        telemetry_table = os.getenv('DYNAMODB_STATION_TELEMETRY_TABLE', 'ecovolt-dev-station-telemetry')
        
        telemetry_items = DynamoDBHelper.query(
            table_name=telemetry_table,
            key_condition='station_id = :station_id',
            expression_values={':station_id': station_id}
        )
        
        if not telemetry_items:
            return None
        
        # Sort by timestamp and get latest
        telemetry_items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return telemetry_items[0]
        
    except Exception as e:
        print(f"Error getting station telemetry: {str(e)}")
        return None
