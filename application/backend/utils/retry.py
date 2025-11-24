"""
Retry Logic Utilities
Implements exponential backoff for database and external service calls
"""

import time
from typing import Callable, Any, TypeVar, Optional
from functools import wraps

T = TypeVar('T')


def exponential_backoff_retry(
    func: Callable[..., T],
    max_attempts: int = 3,
    initial_delay: float = 0.1,
    max_delay: float = 2.0,
    backoff_factor: float = 2.0
) -> Optional[T]:
    """
    Retry function with exponential backoff
    
    Requirements: 14.4
    
    Args:
        func: Function to retry
        max_attempts: Maximum number of attempts (default 3)
        initial_delay: Initial delay in seconds (default 0.1)
        max_delay: Maximum delay in seconds (default 2.0)
        backoff_factor: Backoff multiplier (default 2.0)
        
    Returns:
        Function result if successful, None if all attempts fail
    """
    delay = initial_delay
    
    for attempt in range(1, max_attempts + 1):
        try:
            return func()
        except Exception as e:
            if attempt == max_attempts:
                print(f"All {max_attempts} retry attempts failed: {str(e)}")
                raise
            
            print(f"Attempt {attempt} failed: {str(e)}. Retrying in {delay}s...")
            time.sleep(delay)
            delay = min(delay * backoff_factor, max_delay)
    
    return None


def retry_on_db_error(max_attempts: int = 3):
    """
    Decorator for retrying database operations
    
    Requirements: 14.4
    
    Usage:
        @retry_on_db_error(max_attempts=3)
        def query_database():
            # database operation
            pass
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            return exponential_backoff_retry(
                lambda: func(*args, **kwargs),
                max_attempts=max_attempts,
                initial_delay=0.1,
                max_delay=0.4,
                backoff_factor=2.0
            )
        return wrapper
    return decorator


def retry_on_dynamodb_error(max_attempts: int = 3):
    """
    Decorator for retrying DynamoDB operations
    
    Requirements: 14.4
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            return exponential_backoff_retry(
                lambda: func(*args, **kwargs),
                max_attempts=max_attempts,
                initial_delay=0.1,
                max_delay=0.4,
                backoff_factor=2.0
            )
        return wrapper
    return decorator
