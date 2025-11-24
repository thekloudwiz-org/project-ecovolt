"""
Logging Utilities
Structured logging with correlation IDs
"""

import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logger
logger = logging.getLogger('ecovolt')
logger.setLevel(logging.INFO)


def log_request(
    correlation_id: str,
    method: str,
    path: str,
    user_id: Optional[str] = None,
    body: Optional[Dict] = None
) -> None:
    """
    Log API request
    
    Requirements: 14.2, 14.5
    """
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'level': 'INFO',
        'type': 'request',
        'correlation_id': correlation_id,
        'method': method,
        'path': path,
        'user_id': user_id
    }
    
    if body:
        # Don't log sensitive data
        safe_body = {k: v for k, v in body.items() if k not in ['password', 'token']}
        log_entry['body'] = safe_body
    
    logger.info(json.dumps(log_entry))


def log_response(
    correlation_id: str,
    status_code: int,
    duration_ms: float,
    user_id: Optional[str] = None
) -> None:
    """
    Log API response
    
    Requirements: 14.2, 14.5
    """
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'level': 'INFO',
        'type': 'response',
        'correlation_id': correlation_id,
        'status_code': status_code,
        'duration_ms': duration_ms,
        'user_id': user_id
    }
    
    logger.info(json.dumps(log_entry))


def log_error(
    correlation_id: str,
    error: Exception,
    endpoint: str,
    user_id: Optional[str] = None,
    stack_trace: Optional[str] = None
) -> None:
    """
    Log error with stack trace
    
    Requirements: 14.2, 14.5
    """
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'level': 'ERROR',
        'type': 'error',
        'correlation_id': correlation_id,
        'endpoint': endpoint,
        'error': str(error),
        'error_type': type(error).__name__,
        'user_id': user_id
    }
    
    if stack_trace:
        log_entry['stack_trace'] = stack_trace
    
    logger.error(json.dumps(log_entry))


def log_business_event(
    correlation_id: str,
    event_type: str,
    event_data: Dict[str, Any],
    user_id: Optional[str] = None
) -> None:
    """
    Log business event
    
    Requirements: 14.2
    """
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'level': 'INFO',
        'type': 'business_event',
        'correlation_id': correlation_id,
        'event_type': event_type,
        'event_data': event_data,
        'user_id': user_id
    }
    
    logger.info(json.dumps(log_entry))
