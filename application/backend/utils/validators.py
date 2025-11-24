"""
Input Validation Utilities
Validates user inputs for API endpoints
"""

import re
from typing import Tuple, Dict, Any, Optional
from math import radians, cos, sin, asin, sqrt


def validate_email(email: str) -> bool:
    """
    Validate email format
    
    Args:
        email: Email address to validate
        
    Returns:
        True if valid, False otherwise
    """
    if not email:
        return False
    
    # Basic email regex pattern
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_password(password: str) -> Tuple[bool, Optional[str]]:
    """
    Validate password meets requirements:
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one number
    
    Requirements: 1.5
    
    Args:
        password: Password to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    if not password:
        return False, "Password is required"
    
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    
    if not re.search(r'[0-9]', password):
        return False, "Password must contain at least one number"
    
    return True, None


def validate_phone_number(phone: str) -> bool:
    """
    Validate Ghanaian phone number format: +233XXXXXXXXX
    
    Requirements: 15.2
    
    Args:
        phone: Phone number to validate
        
    Returns:
        True if valid, False otherwise
    """
    if not phone:
        return False
    
    # Ghanaian phone number pattern: +233 followed by 9 digits
    pattern = r'^\+233\d{9}$'
    return bool(re.match(pattern, phone))


def validate_coordinates(latitude: float, longitude: float) -> Tuple[bool, Optional[str]]:
    """
    Validate geographic coordinates
    
    Requirements: 2.1, 9.2
    
    Args:
        latitude: Latitude value
        longitude: Longitude value
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        lat = float(latitude)
        lon = float(longitude)
        
        if lat < -90 or lat > 90:
            return False, "Latitude must be between -90 and 90"
        
        if lon < -180 or lon > 180:
            return False, "Longitude must be between -180 and 180"
        
        return True, None
        
    except (ValueError, TypeError):
        return False, "Coordinates must be valid numbers"


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two points using Haversine formula
    Returns distance in kilometers
    
    Requirements: 2.3
    
    Args:
        lat1: Latitude of first point
        lon1: Longitude of first point
        lat2: Latitude of second point
        lon2: Longitude of second point
        
    Returns:
        Distance in kilometers
    """
    # Convert to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    
    # Earth radius in kilometers
    r = 6371
    
    return c * r


def validate_amount(amount: float, min_amount: float = 0, max_amount: float = None) -> Tuple[bool, Optional[str]]:
    """
    Validate monetary amount
    
    Requirements: 6.1, 6.6
    
    Args:
        amount: Amount to validate
        min_amount: Minimum allowed amount (default 0)
        max_amount: Maximum allowed amount (optional)
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        amt = float(amount)
        
        if amt < min_amount:
            return False, f"Amount must be at least {min_amount}"
        
        if max_amount is not None and amt > max_amount:
            return False, f"Amount must not exceed {max_amount}"
        
        return True, None
        
    except (ValueError, TypeError):
        return False, "Amount must be a valid number"


def validate_wallet_topup(amount: float) -> Tuple[bool, Optional[str]]:
    """
    Validate wallet top-up amount (10-1000 GHS)
    
    Requirements: 6.1, 6.6
    
    Args:
        amount: Top-up amount
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    return validate_amount(amount, min_amount=10, max_amount=1000)


def validate_station_data(data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    Validate station creation/update data
    
    Requirements: 9.1, 9.2
    
    Args:
        data: Station data dictionary
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    # Required fields for station creation
    required_fields = ['name', 'latitude', 'longitude', 'address', 'city', 'total_capacity', 'pricing']
    
    # Check required fields
    for field in required_fields:
        if field not in data or data[field] is None or data[field] == '':
            return False, f"Missing required field: {field}"
    
    # Validate coordinates
    coords_valid, coords_error = validate_coordinates(data['latitude'], data['longitude'])
    if not coords_valid:
        return False, coords_error
    
    # Validate capacity
    try:
        capacity = int(data['total_capacity'])
        if capacity <= 0:
            return False, "Total capacity must be greater than 0"
    except (ValueError, TypeError):
        return False, "Total capacity must be a valid integer"
    
    # Validate name length
    if len(data['name'].strip()) < 3:
        return False, "Station name must be at least 3 characters"
    
    # Validate address length
    if len(data['address'].strip()) < 5:
        return False, "Address must be at least 5 characters"
    
    return True, None


def validate_swap_request(data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    Validate battery swap request data
    
    Requirements: 3.1, 3.2, 3.3
    
    Args:
        data: Swap request data dictionary
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    # Required fields
    required_fields = ['bike_id', 'station_id']
    
    # Check required fields
    for field in required_fields:
        if field not in data or not data[field]:
            return False, f"Missing required field: {field}"
    
    # Validate IDs are not empty strings
    if not data['bike_id'].strip():
        return False, "bike_id cannot be empty"
    
    if not data['station_id'].strip():
        return False, "station_id cannot be empty"
    
    return True, None


def validate_pagination(page: int = 1, page_size: int = 20, max_page_size: int = 100) -> Tuple[bool, Optional[str], int, int]:
    """
    Validate and normalize pagination parameters
    
    Requirements: 5.3, 5.4
    
    Args:
        page: Page number (1-indexed)
        page_size: Number of items per page
        max_page_size: Maximum allowed page size
        
    Returns:
        Tuple of (is_valid, error_message, normalized_page, normalized_page_size)
    """
    try:
        p = int(page)
        ps = int(page_size)
        
        if p < 1:
            return False, "Page number must be at least 1", 1, page_size
        
        if ps < 1:
            return False, "Page size must be at least 1", page, 1
        
        if ps > max_page_size:
            return False, f"Page size must not exceed {max_page_size}", page, max_page_size
        
        return True, None, p, ps
        
    except (ValueError, TypeError):
        return False, "Page and page_size must be valid integers", 1, 20


def validate_required_fields(data: Dict[str, Any], required_fields: list) -> Tuple[bool, Optional[str]]:
    """
    Generic validator for required fields
    
    Args:
        data: Data dictionary to validate
        required_fields: List of required field names
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    for field in required_fields:
        if field not in data or data[field] is None or data[field] == '':
            return False, f"Missing required field: {field}"
    
    return True, None


def sanitize_string(value: str, max_length: int = None) -> str:
    """
    Sanitize string input by trimming whitespace and limiting length
    
    Args:
        value: String to sanitize
        max_length: Maximum allowed length (optional)
        
    Returns:
        Sanitized string
    """
    if not value:
        return ''
    
    sanitized = value.strip()
    
    if max_length and len(sanitized) > max_length:
        sanitized = sanitized[:max_length]
    
    return sanitized


def validate_date_range(start_date: str, end_date: str) -> Tuple[bool, Optional[str]]:
    """
    Validate date range for analytics queries
    
    Requirements: 11.5
    
    Args:
        start_date: Start date in ISO format (YYYY-MM-DD)
        end_date: End date in ISO format (YYYY-MM-DD)
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    from datetime import datetime
    
    try:
        start = datetime.fromisoformat(start_date)
        end = datetime.fromisoformat(end_date)
        
        if start > end:
            return False, "Start date must be before or equal to end date"
        
        # Check if date range is reasonable (not more than 1 year)
        delta = end - start
        if delta.days > 365:
            return False, "Date range cannot exceed 365 days"
        
        return True, None
        
    except (ValueError, TypeError):
        return False, "Invalid date format. Use YYYY-MM-DD"


def validate_bike_id(bike_id: str) -> Tuple[bool, Optional[str]]:
    """
    Validate bike ID format
    
    Args:
        bike_id: Bike ID to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    if not bike_id or not bike_id.strip():
        return False, "Bike ID is required"
    
    # Basic validation - alphanumeric and hyphens
    if not re.match(r'^[a-zA-Z0-9-_]+$', bike_id):
        return False, "Bike ID must contain only alphanumeric characters, hyphens, and underscores"
    
    if len(bike_id) < 3 or len(bike_id) > 50:
        return False, "Bike ID must be between 3 and 50 characters"
    
    return True, None


def validate_station_id(station_id: str) -> Tuple[bool, Optional[str]]:
    """
    Validate station ID format
    
    Args:
        station_id: Station ID to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    if not station_id or not station_id.strip():
        return False, "Station ID is required"
    
    # Basic validation - alphanumeric and hyphens
    if not re.match(r'^[a-zA-Z0-9-_]+$', station_id):
        return False, "Station ID must contain only alphanumeric characters, hyphens, and underscores"
    
    if len(station_id) < 3 or len(station_id) > 50:
        return False, "Station ID must be between 3 and 50 characters"
    
    return True, None
