"""
Test retry logic implementation
"""

import pytest
from unittest.mock import Mock, patch
from utils.retry import exponential_backoff_retry, retry_on_db_error, retry_on_dynamodb_error


def test_exponential_backoff_success_on_first_attempt():
    """Test that function succeeds on first attempt"""
    mock_func = Mock(return_value="success")
    result = exponential_backoff_retry(mock_func, max_attempts=3)
    
    assert result == "success"
    assert mock_func.call_count == 1


def test_exponential_backoff_success_on_retry():
    """Test that function succeeds after retries"""
    mock_func = Mock(side_effect=[Exception("fail"), Exception("fail"), "success"])
    result = exponential_backoff_retry(mock_func, max_attempts=3)
    
    assert result == "success"
    assert mock_func.call_count == 3


def test_exponential_backoff_all_attempts_fail():
    """Test that function raises exception after all attempts fail"""
    mock_func = Mock(side_effect=Exception("fail"))
    
    with pytest.raises(Exception, match="fail"):
        exponential_backoff_retry(mock_func, max_attempts=3)
    
    assert mock_func.call_count == 3


def test_retry_on_db_error_decorator():
    """Test database retry decorator"""
    call_count = 0
    
    @retry_on_db_error(max_attempts=3)
    def failing_db_operation():
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise Exception("Database connection failed")
        return "success"
    
    result = failing_db_operation()
    assert result == "success"
    assert call_count == 3


def test_retry_on_dynamodb_error_decorator():
    """Test DynamoDB retry decorator"""
    call_count = 0
    
    @retry_on_dynamodb_error(max_attempts=3)
    def failing_dynamodb_operation():
        nonlocal call_count
        call_count += 1
        if call_count < 2:
            raise Exception("DynamoDB throttling")
        return "success"
    
    result = failing_dynamodb_operation()
    assert result == "success"
    assert call_count == 2


def test_exponential_backoff_timing():
    """Test that exponential backoff delays are correct"""
    import time
    
    call_times = []
    
    def failing_func():
        call_times.append(time.time())
        if len(call_times) < 3:
            raise Exception("fail")
        return "success"
    
    result = exponential_backoff_retry(
        failing_func, 
        max_attempts=3, 
        initial_delay=0.1,
        backoff_factor=2.0
    )
    
    assert result == "success"
    assert len(call_times) == 3
    
    # Check that delays are approximately correct (with some tolerance)
    if len(call_times) >= 2:
        delay1 = call_times[1] - call_times[0]
        assert 0.08 <= delay1 <= 0.15  # ~0.1s with tolerance
    
    if len(call_times) >= 3:
        delay2 = call_times[2] - call_times[1]
        assert 0.18 <= delay2 <= 0.25  # ~0.2s with tolerance


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
