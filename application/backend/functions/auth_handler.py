"""
Authentication Handler Lambda
Handles only authentication endpoints outside VPC for Cognito access
"""

import json
import os
from typing import Dict, Any
from api import auth

# Auth routes mapping
AUTH_ROUTES = {
    'POST /auth/register': auth.register,
    'POST /auth/login': auth.login,
    'POST /auth/confirm': auth.confirm,
    'POST /auth/refresh': auth.refresh,
}


def generate_correlation_id() -> str:
    """Generate a unique correlation ID for request tracking"""
    import uuid
    return f"AUTH-{uuid.uuid4()}"


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Auth Lambda handler for authentication endpoints only
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    # Generate correlation ID
    correlation_id = generate_correlation_id()
    
    # CORS headers
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Correlation-ID',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'X-Correlation-ID': correlation_id
    }
    
    try:
        # Extract request details
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        route_key = f"{http_method} {path}"
        
        # Structured logging
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'auth_request_received',
            'method': http_method,
            'path': path,
            'route_key': route_key,
            'source_ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp')
        }))
        
        # Handle OPTIONS for CORS preflight
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        # Check if route exists
        handler_func = AUTH_ROUTES.get(route_key)
        if not handler_func:
            print(json.dumps({
                'correlation_id': correlation_id,
                'event': 'auth_route_not_found',
                'route_key': route_key
            }))
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Route not found',
                    'correlation_id': correlation_id
                })
            }
        
        # Add correlation ID to event
        event['correlation_id'] = correlation_id
        
        # Call the route handler
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'auth_handler_invoked',
            'route_key': route_key
        }))
        
        response = handler_func(event, context)
        
        # Ensure headers are included
        if 'headers' not in response:
            response['headers'] = headers
        else:
            response['headers'].update(headers)
        
        # Log response
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'auth_request_completed',
            'route_key': route_key,
            'status_code': response.get('statusCode')
        }))
        
        return response
        
    except Exception as e:
        # Error logging
        print(json.dumps({
            'correlation_id': correlation_id,
            'event': 'auth_request_error',
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
