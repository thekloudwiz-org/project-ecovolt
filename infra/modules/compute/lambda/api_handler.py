"""
API Handler Lambda Function
Handles backend API operations for EcoVolt system
"""
import json
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Main Lambda handler for API Gateway requests
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Extract request details
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    body = event.get('body', '{}')
    
    try:
        # Parse request body if present
        if body:
            request_data = json.loads(body)
        else:
            request_data = {}
        
        # Route based on HTTP method and path
        if http_method == 'GET' and path == '/health':
            return health_check()
        elif http_method == 'GET' and path.startswith('/bikes'):
            return get_bikes(event, request_data)
        elif http_method == 'POST' and path == '/bikes':
            return create_bike(request_data)
        elif http_method == 'GET' and path.startswith('/stations'):
            return get_stations(event, request_data)
        elif http_method == 'POST' and path == '/stations':
            return create_station(request_data)
        elif http_method == 'GET' and path.startswith('/swaps'):
            return get_swaps(event, request_data)
        elif http_method == 'POST' and path == '/swaps':
            return create_swap(request_data)
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Not Found',
                    'message': f'Route not found: {http_method} {path}'
                })
            }
            
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return error_response(400, 'Invalid JSON in request body')
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return error_response(500, 'Internal server error')


def health_check():
    """Health check endpoint"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'healthy',
            'service': 'ecovolt-api',
            'version': '1.0.0'
        })
    }


def get_bikes(event, request_data):
    """Get bikes (list or single)"""
    path_parameters = event.get('pathParameters', {})
    bike_id = path_parameters.get('id') if path_parameters else None
    
    if bike_id:
        # Get single bike
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'bike_id': bike_id,
                'model': 'EcoVolt E-Bike',
                'status': 'active'
            })
        }
    else:
        # List bikes
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'bikes': [],
                'count': 0
            })
        }


def create_bike(request_data):
    """Create a new bike"""
    # Validate required fields
    required_fields = ['model', 'vin']
    for field in required_fields:
        if field not in request_data:
            return error_response(400, f'Missing required field: {field}')
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'bike_id': 'bike-123',
            'model': request_data['model'],
            'vin': request_data['vin'],
            'status': 'active'
        })
    }


def get_stations(event, request_data):
    """Get stations (list or single)"""
    path_parameters = event.get('pathParameters', {})
    station_id = path_parameters.get('id') if path_parameters else None
    
    if station_id:
        # Get single station
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'station_id': station_id,
                'name': 'Downtown Station',
                'status': 'active'
            })
        }
    else:
        # List stations
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'stations': [],
                'count': 0
            })
        }


def create_station(request_data):
    """Create a new station"""
    # Validate required fields
    required_fields = ['name', 'latitude', 'longitude']
    for field in required_fields:
        if field not in request_data:
            return error_response(400, f'Missing required field: {field}')
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'station_id': 'station-123',
            'name': request_data['name'],
            'latitude': request_data['latitude'],
            'longitude': request_data['longitude'],
            'status': 'active'
        })
    }


def get_swaps(event, request_data):
    """Get swap events"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'swaps': [],
            'count': 0
        })
    }


def create_swap(request_data):
    """Create a new swap event"""
    # Validate required fields
    required_fields = ['station_id', 'bike_id', 'removed_battery_id', 'installed_battery_id']
    for field in required_fields:
        if field not in request_data:
            return error_response(400, f'Missing required field: {field}')
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'swap_id': 'swap-123',
            'station_id': request_data['station_id'],
            'bike_id': request_data['bike_id'],
            'removed_battery_id': request_data['removed_battery_id'],
            'installed_battery_id': request_data['installed_battery_id'],
            'timestamp': '2024-01-01T00:00:00Z'
        })
    }


def error_response(status_code, message):
    """Generate error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': True,
            'message': message
        })
    }
