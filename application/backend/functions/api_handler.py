"""
EcoVolt API Handler
Main Lambda function handler for API Gateway requests
"""

import json
import os
from typing import Dict, Any
from api import auth, stations, swaps, users, admin, bikes, notifications
from utils.auth import verify_token

# API Routes mapping
ROUTES = {
    # Public routes
    'GET /health': lambda event, context: {'statusCode': 200, 'body': json.dumps({'status': 'healthy'})},
    'GET /stations': stations.list_stations,
    'GET /stations/{id}': stations.get_station,
    'GET /stations/{id}/availability': stations.get_station_availability,
    'GET /stations/nearby': stations.find_nearby,
    
    # Authentication routes (public)
    'POST /auth/register': auth.register,
    'POST /auth/login': auth.login,
    'POST /auth/confirm': auth.confirm,
    'POST /auth/refresh': auth.refresh,
    
    # Authenticated routes (riders)
    'GET /profile': users.get_profile,
    'PUT /profile': users.update_profile,
    'GET /bikes/{id}': bikes.get_bike_details,
    'GET /wallet': users.get_wallet,
    'POST /wallet/topup': users.topup_wallet,
    'GET /wallet/transactions': users.get_wallet_transactions,
    
    # Swap routes
    'POST /swaps': swaps.initiate_swap,
    'PUT /swaps/{id}/complete': swaps.complete_swap,
    'GET /swaps/{id}': swaps.get_swap_status,
    'GET /swaps/history': swaps.get_swap_history,
    
    # Notification routes
    'GET /notifications': notifications.get_notifications,
    'PUT /notifications/{id}/read': notifications.mark_notification_read,
    
    # Admin dashboard and analytics routes
    'GET /admin/dashboard': admin.get_dashboard,
    'GET /admin/analytics': admin.get_analytics,
    'GET /admin/analytics/stations': admin.get_station_analytics,
    'GET /admin/analytics/revenue': admin.get_revenue_analytics,
    'GET /admin/analytics/batteries': admin.get_battery_analytics,
    
    # Admin station management routes
    'GET /admin/stations': admin.list_stations,
    'POST /admin/stations': admin.create_station,
    'PUT /admin/stations/{id}': admin.update_station,
    'DELETE /admin/stations/{id}': admin.delete_station,
    
    # Admin bike management routes
    'GET /admin/bikes': admin.list_bikes,
    'POST /admin/bikes': admin.register_bike,
    'PUT /admin/bikes/{id}': admin.update_bike,
    'PUT /admin/bikes/{id}/assign': admin.assign_bike,
    'PUT /admin/bikes/{id}/unassign': admin.unassign_bike,

    # Admin user management routes
    'GET /admin/users': admin.list_users,
    'GET /admin/users/{id}': admin.get_user_details,
    'PUT /admin/users/{id}/wallet': admin.adjust_user_wallet,
}

# Public routes that don't require authentication
PUBLIC_ROUTES = [
    'GET /health',
    'GET /stations',
    'GET /stations/{id}',
    'GET /stations/{id}/availability',
    'GET /stations/nearby',
    'POST /auth/register',
    'POST /auth/login',
    'POST /auth/confirm',
    'POST /auth/refresh',
]


def match_route(http_method: str, path: str, routes: Dict[str, Any]) -> tuple:
    """
    Match incoming request to a route pattern with path parameters

    Args:
        http_method: HTTP method (GET, POST, PUT, DELETE)
        path: Request path (e.g., /admin/stations/STN-123)
        routes: Dictionary of route patterns

    Returns:
        Tuple of (handler_function, path_parameters, route_key) or (None, None, None)
    """
    import re

    # First try exact match
    route_key = f"{http_method} {path}"
    if route_key in routes:
        return routes[route_key], {}, route_key

    # Try pattern matching for parameterized routes
    for route_pattern, handler_func in routes.items():
        # Extract method and path pattern
        pattern_parts = route_pattern.split(' ', 1)
        if len(pattern_parts) != 2:
            continue

        pattern_method, pattern_path = pattern_parts

        # Check if method matches
        if pattern_method != http_method:
            continue

        # Convert route pattern to regex
        # Replace {id} with named capture group
        regex_pattern = re.sub(r'\{(\w+)\}', r'(?P<\1>[^/]+)', pattern_path)
        regex_pattern = f"^{regex_pattern}$"

        # Try to match
        match = re.match(regex_pattern, path)
        if match:
            path_params = match.groupdict()
            return handler_func, path_params, route_pattern

    return None, None, None


def generate_correlation_id() -> str:
    """Generate a unique correlation ID for request tracking"""
    import uuid
    return f"REQ-{uuid.uuid4()}"


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for API Gateway requests
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    
    Requirements: 1.4, 8.1, 9.6, 14.1, 14.2, 14.3, 14.5
    """
    # Generate correlation ID for request tracking
    correlation_id = generate_correlation_id()
    
    # CORS headers
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Correlation-ID',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'X-Correlation-ID': correlation_id
    }
    
    try:
        # Extract request details
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')

        # Requirement 14.2: Structured logging with correlation ID
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'request_received',
            'method': http_method,
            'path': path,
            'source_ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp'),
            'user_agent': event.get('headers', {}).get('User-Agent')
        }))

        # Handle OPTIONS for CORS preflight
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }

        # Match route pattern and extract path parameters
        handler_func, path_params, route_key = match_route(http_method, path, ROUTES)

        if not handler_func:
            print(json.dumps({
                'correlation_id': correlation_id,
                'event': 'route_not_found',
                'method': http_method,
                'path': path
            }))
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Route not found',
                    'correlation_id': correlation_id
                })
            }

        # Add path parameters to event
        if path_params:
            if 'pathParameters' not in event:
                event['pathParameters'] = {}
            event['pathParameters'].update(path_params)

        # Requirement 1.4: Authentication middleware
        if route_key not in PUBLIC_ROUTES:
            # Get authorization header (case-insensitive)
            auth_header = event.get('headers', {}).get('Authorization') or \
                         event.get('headers', {}).get('authorization', '')
            
            if not auth_header:
                print(json.dumps({
                    'correlation_id': correlation_id,
                    'event': 'auth_missing',
                    'route_key': route_key
                }))
                return {
                    'statusCode': 401,
                    'headers': headers,
                    'body': json.dumps({
                        'error': 'Missing authorization header',
                        'correlation_id': correlation_id
                    })
                }
            
            # Verify JWT token
            token = auth_header.replace('Bearer ', '').replace('bearer ', '')
            user = verify_token(token)
            
            if not user:
                print(json.dumps({
                    'correlation_id': correlation_id,
                    'event': 'auth_failed',
                    'route_key': route_key
                }))
                return {
                    'statusCode': 401,
                    'headers': headers,
                    'body': json.dumps({
                        'error': 'Invalid or expired token',
                        'correlation_id': correlation_id
                    })
                }
            
            # Add user and correlation ID to event for downstream handlers
            event['user'] = user
            event['correlation_id'] = correlation_id
            
            # Ensure user record exists in database (lazy creation)
            from utils.user_sync import ensure_user_exists
            db_user = ensure_user_exists(user)
            if db_user:
                event['db_user'] = db_user
            
            print(json.dumps({
                'correlation_id': correlation_id,
                'event': 'auth_success',
                'user_id': user.get('user_id') or user.get('sub'),
                'route_key': route_key,
                'db_user_synced': db_user is not None
            }))
            
            # Requirement 8.1, 9.6: Check admin routes authorization
            if route_key.startswith('GET /admin') or \
               route_key.startswith('POST /admin') or \
               route_key.startswith('PUT /admin') or \
               route_key.startswith('DELETE /admin'):
                # Check if user has admin role
                groups = user.get('groups', [])
                if isinstance(groups, str):
                    groups = [groups]
                
                # Debug: log user claims
                print(json.dumps({
                    'event': 'admin_check',
                    'user_id': user.get('user_id') or user.get('sub'),
                    'groups': groups,
                    'all_claims': list(user.keys())
                }))
                
                is_admin = 'admin' in groups or 'admins' in groups or user.get('is_admin', False)
                
                if not is_admin:
                    print(json.dumps({
                        'correlation_id': correlation_id,
                        'event': 'admin_access_denied',
                        'user_id': user.get('user_id') or user.get('sub'),
                        'route_key': route_key
                    }))
                    return {
                        'statusCode': 403,
                        'headers': headers,
                        'body': json.dumps({
                            'error': 'Admin access required',
                            'correlation_id': correlation_id
                        })
                    }
        else:
            # Add correlation ID to event for public routes too
            event['correlation_id'] = correlation_id
        
        # Call the route handler
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'handler_invoked',
            'route_key': route_key
        }))
        
        response = handler_func(event, context)
        
        # Ensure headers are included
        if 'headers' not in response:
            response['headers'] = headers
        else:
            response['headers'].update(headers)
        
        # Requirement 14.2: Log response
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'request_completed',
            'route_key': route_key,
            'status_code': response.get('statusCode')
        }))
        
        return response
        
    except Exception as e:
        # Requirement 14.5: Error logging with stack traces
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'request_error',
            'error': str(e),
            'error_type': type(e).__name__
        }))
        
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred',
                'correlation_id': correlation_id
            })
        }


# For local testing
if __name__ == '__main__':
    # Test event
    test_event = {
        'httpMethod': 'GET',
        'path': '/health',
        'headers': {},
        'body': None
    }
    
    result = handler(test_event, None)
    print(json.dumps(result, indent=2))
