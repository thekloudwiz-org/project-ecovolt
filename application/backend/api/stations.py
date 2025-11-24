"""
Stations API Endpoints
Handles station-related operations
"""

import json
from typing import Dict, Any
from utils.db import get_db_connection, Queries
from utils.validators import validate_coordinates, validate_station_data


def list_stations(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /stations
    List all active stations
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.GET_ALL_STATIONS)
            stations = cursor.fetchall()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'stations': [dict(station) for station in stations],
                'count': len(stations)
            })
        }
        
    except Exception as e:
        print(f"Error listing stations: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to fetch stations'})
        }


def get_station(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /stations/{id}
    Get station details by ID
    """
    try:
        station_id = event.get('pathParameters', {}).get('id')
        if not station_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Station ID required'})
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.GET_STATION_BY_ID, (station_id,))
            station = cursor.fetchone()
        
        if not station:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Station not found'})
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({'station': dict(station)})
        }
        
    except Exception as e:
        print(f"Error getting station: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to fetch station'})
        }


def find_nearby(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /stations/nearby?lat={lat}&lng={lng}&radius={radius}&limit={limit}
    Find nearby stations
    """
    try:
        params = event.get('queryStringParameters', {})
        
        # Validate coordinates
        lat = params.get('lat')
        lng = params.get('lng')
        
        if not lat or not lng:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Latitude and longitude required'})
            }
        
        try:
            lat = float(lat)
            lng = float(lng)
        except ValueError:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid coordinates'})
            }
        
        if not validate_coordinates(lat, lng):
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Coordinates out of range'})
            }
        
        # Optional parameters
        radius = float(params.get('radius', 10))  # Default 10km
        limit = int(params.get('limit', 10))  # Default 10 stations
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                Queries.GET_NEARBY_STATIONS,
                (lat, lng, lat, radius, limit)
            )
            stations = cursor.fetchall()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'stations': [dict(station) for station in stations],
                'count': len(stations),
                'search_location': {'lat': lat, 'lng': lng},
                'radius_km': radius
            })
        }
        
    except Exception as e:
        print(f"Error finding nearby stations: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to find nearby stations'})
        }


def get_station_availability(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /stations/{id}/availability
    Get real-time battery availability for a station
    """
    try:
        station_id = event.get('pathParameters', {}).get('id')
        if not station_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Station ID required'})
            }
        
        # Get station info
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.GET_STATION_BY_ID, (station_id,))
            station = cursor.fetchone()
        
        if not station:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Station not found'})
            }
        
        # Get battery availability from DynamoDB (real-time data)
        from utils.db import DynamoDBHelper
        import os
        
        batteries = DynamoDBHelper.query(
            table_name=os.getenv('DYNAMODB_BATTERIES_TABLE', 'ecovolt-dev-batteries'),
            key_condition='station_id = :station_id AND #status = :status',
            expression_values={
                ':station_id': station_id,
                ':status': 'available'
            }
        )
        
        available_count = len([b for b in batteries if b.get('charge_level', 0) >= 80])
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'station_id': station_id,
                'station_name': station['name'],
                'available_batteries': available_count,
                'total_capacity': station['total_capacity'],
                'availability_percentage': (available_count / station['total_capacity'] * 100) if station['total_capacity'] > 0 else 0,
                'batteries': [dict(b) for b in batteries]
            })
        }
        
    except Exception as e:
        print(f"Error getting station availability: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to get availability'})
        }
