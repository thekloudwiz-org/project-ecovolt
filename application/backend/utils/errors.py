"""
Error Handling Utilities
Standardized error responses and correlation IDs
"""

import json
import uuid
from typing import Dict, Any, Optional


def generate_correlation_id() -> str:
    """
    Generate unique correlation ID for request tracing
    
    Requirements: 14.5
    """
    return f"REQ-{uuid.uuid4()}"


class ErrorCodes:
    """Standard error codes"""
    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    AUTHORIZATION_ERROR = "AUTHORIZATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    INSUFFICIENT_BALANCE = "INSUFFICIENT_BALANCE"
    RESOURCE_UNAVAILABLE = "RESOURCE_UNAVAILABLE"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    DATABASE_ERROR = "DATABASE_ERROR"
    EXTERNAL_SERVICE_ERROR = "EXTERNAL_SERVICE_ERROR"


def build_error_response(
    status_code: int,
    error_message: str,
    error_code: str = None,
    details: Any = None,
    correlation_id: str = None
) -> Dict[str, Any]:
    """
    Build standardized error response
    
    Requirements: 14.1, 14.3
    
    Args:
        status_code: HTTP status code
        error_message: Human-readable error message
        error_code: Machine-readable error code
        details: Additional error details
        correlation_id: Request correlation ID
        
    Returns:
        Standardized error response dictionary
    """
    if not correlation_id:
        correlation_id = generate_correlation_id()
    
    response_body = {
        'error': error_message,
        'correlation_id': correlation_id
    }
    
    if error_code:
        response_body['code'] = error_code
    
    if details:
        response_body['details'] = details
    
    return {
        'statusCode': status_code,
        'body': json.dumps(response_body),
        'headers': {
            'Content-Type': 'application/json',
            'X-Correlation-ID': correlation_id
        }
    }


def validation_error(message: str, details: Any = None, correlation_id: str = None) -> Dict[str, Any]:
    """Build 400 validation error response"""
    return build_error_response(400, message, ErrorCodes.VALIDATION_ERROR, details, correlation_id)


def authentication_error(message: str = "Authentication required", correlation_id: str = None) -> Dict[str, Any]:
    """Build 401 authentication error response"""
    return build_error_response(401, message, ErrorCodes.AUTHENTICATION_ERROR, None, correlation_id)


def authorization_error(message: str = "Insufficient permissions", correlation_id: str = None) -> Dict[str, Any]:
    """Build 403 authorization error response"""
    return build_error_response(403, message, ErrorCodes.AUTHORIZATION_ERROR, None, correlation_id)


def not_found_error(resource: str, correlation_id: str = None) -> Dict[str, Any]:
    """Build 404 not found error response"""
    return build_error_response(404, f"{resource} not found", ErrorCodes.NOT_FOUND, None, correlation_id)


def conflict_error(message: str, correlation_id: str = None) -> Dict[str, Any]:
    """Build 409 conflict error response"""
    return build_error_response(409, message, ErrorCodes.CONFLICT, None, correlation_id)


def internal_error(message: str = "Internal server error", details: Any = None, correlation_id: str = None) -> Dict[str, Any]:
    """Build 500 internal error response"""
    return build_error_response(500, message, ErrorCodes.INTERNAL_ERROR, details, correlation_id)


def success_response(data: Any, status_code: int = 200, correlation_id: str = None) -> Dict[str, Any]:
    """
    Build standardized success response
    
    Args:
        data: Response data
        status_code: HTTP status code (default 200)
        correlation_id: Request correlation ID
        
    Returns:
        Standardized success response dictionary
    """
    if not correlation_id:
        correlation_id = generate_correlation_id()
    
    return {
        'statusCode': status_code,
        'body': json.dumps(data),
        'headers': {
            'Content-Type': 'application/json',
            'X-Correlation-ID': correlation_id
        }
    }
