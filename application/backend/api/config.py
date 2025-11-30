"""
Runtime configuration endpoint
Serves public configuration values to frontend applications
"""

import json
import os
from typing import Dict, Any


def get_config(event: Dict[str, Any], context: Any = None) -> Dict[str, Any]:
    """
    Get runtime configuration for frontend applications
    Returns public configuration values from environment variables

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response with configuration
    """
    # These values are not secrets - they're meant to be public
    # Cognito User Pool ID and Client ID are designed to be public
    config = {
        'cognito': {
            'userPoolId': os.environ.get('COGNITO_USER_POOL_ID', ''),
            'clientId': os.environ.get('COGNITO_ADMIN_CLIENT_ID', ''),
            'region': os.environ.get('AWS_REGION', 'eu-central-1')
        },
        'api': {
            'endpoint': os.environ.get('API_GATEWAY_URL', ''),
            'region': os.environ.get('AWS_REGION', 'eu-central-1')
        },
        'environment': os.environ.get('ENVIRONMENT', 'dev')
    }

    return {
        'statusCode': 200,
        'body': json.dumps(config),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=300'  # Cache for 5 minutes
        }
    }
