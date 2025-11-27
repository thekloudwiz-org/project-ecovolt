"""
Bikes API Endpoints
Handles bike-related operations
"""

import json
import os
from typing import Dict, Any
from datetime import datetime
from utils.db import get_db_connection, DynamoDBHelper, Queries
from models.bike import Bike, BikeTelemetry


def get_bike_details(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /bikes/{id}
    Get bike details with ownership check
    
    Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        # Get bike ID from path
        bike_id = event.get('pathParameters', {}).get('id')
        if not bike_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing bike ID'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.GET_BIKE_BY_ID, (bike_id,))
            bike_data = cursor.fetchone()
        
        if not bike_data:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Bike not found',
                    'details': f'Bike {bike_id} does not exist'
                })
            }
        
        # Requirement 7.1: Verify bike belongs to rider
        # Requirement 7.5: Return authorization error if bike doesn't belong to rider
        if bike_data['user_id'] != user_id:
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'This bike does not belong to you'
                })
            }
        
        # Requirement 7.3: Retrieve real-time battery level from DynamoDB
        telemetry_table = os.getenv('DYNAMODB_TELEMETRY_TABLE')
        
        # Query latest telemetry for this bike
        telemetry_items = DynamoDBHelper.query(
            table_name=telemetry_table,
            key_condition='bike_id = :bike_id',
            expression_values={':bike_id': bike_id}
        )
        
        # Sort by timestamp and get the latest
        if telemetry_items:
            telemetry_items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
            latest_telemetry = telemetry_items[0]
            
            # Parse telemetry data
            telemetry_timestamp = datetime.fromisoformat(latest_telemetry['timestamp'])
            telemetry = BikeTelemetry(
                bike_id=bike_id,
                timestamp=telemetry_timestamp,
                battery_level=latest_telemetry.get('battery_level', 0),
                location=latest_telemetry.get('location', {'lat': 0, 'lng': 0}),
                speed=latest_telemetry.get('speed'),
                odometer=latest_telemetry.get('odometer'),
                temperature=latest_telemetry.get('temperature')
            )
            
            # Requirement 7.4: Include staleness indicator for old telemetry
            is_stale = telemetry.is_stale(max_age_minutes=5)
            freshness = telemetry.get_freshness_indicator()
        else:
            telemetry = None
            is_stale = True
            freshness = "no_data"
        
        # Requirement 7.2: Return bike details including bike_id, model, battery_level, 
        # battery_id, location, odometer, last_swap
        response_data = {
            'bike_id': bike_data['bike_id'],
            'model': bike_data['model'],
            'status': bike_data['status'],
            'battery_id': bike_data['battery_id'],
            'battery_level': bike_data.get('battery_level'),
            'odometer': float(bike_data['odometer']) if bike_data.get('odometer') else None,
            'last_swap': bike_data['last_swap'].isoformat() if bike_data.get('last_swap') else None,
            'created_at': bike_data['created_at'].isoformat() if bike_data.get('created_at') else None,
            'updated_at': bike_data['updated_at'].isoformat() if bike_data.get('updated_at') else None
        }
        
        # Add real-time telemetry if available
        if telemetry:
            response_data['telemetry'] = {
                'battery_level': telemetry.battery_level,
                'location': telemetry.location,
                'speed': telemetry.speed,
                'odometer': telemetry.odometer,
                'temperature': telemetry.temperature,
                'timestamp': telemetry.timestamp.isoformat(),
                'is_stale': is_stale,
                'freshness': freshness
            }
        else:
            response_data['telemetry'] = None
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'bike': response_data
            })
        }
        
    except Exception as e:
        print(f"Error getting bike details: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }
