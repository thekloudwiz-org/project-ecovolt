"""
Test input validators
"""

import pytest
from utils.validators import (
    validate_coordinates,
    validate_phone_number,
    validate_wallet_topup,
    validate_pagination,
    validate_swap_request,
    validate_station_data
)


class TestCoordinateValidation:
    """Test coordinate validation"""
    
    def test_valid_coordinates(self):
        """Test valid latitude and longitude"""
        assert validate_coordinates(5.6037, -0.1870) is True  # Accra
        assert validate_coordinates(0, 0) is True
        assert validate_coordinates(-90, -180) is True
        assert validate_coordinates(90, 180) is True
    
    def test_invalid_latitude(self):
        """Test invalid latitude values"""
        assert validate_coordinates(91, 0) is False
        assert validate_coordinates(-91, 0) is False
        assert validate_coordinates(100, 0) is False
    
    def test_invalid_longitude(self):
        """Test invalid longitude values"""
        assert validate_coordinates(0, 181) is False
        assert validate_coordinates(0, -181) is False
        assert validate_coordinates(0, 200) is False


class TestPhoneNumberValidation:
    """Test phone number validation"""
    
    def test_valid_ghanaian_numbers(self):
        """Test valid Ghanaian phone numbers"""
        assert validate_phone_number("+233201234567") is True
        assert validate_phone_number("+233501234567") is True
        assert validate_phone_number("+233241234567") is True
    
    def test_invalid_format(self):
        """Test invalid phone number formats"""
        assert validate_phone_number("0201234567") is False  # Missing country code
        assert validate_phone_number("+233") is False  # Too short
        assert validate_phone_number("+23320123456") is False  # Too short
        assert validate_phone_number("+2332012345678") is False  # Too long
        assert validate_phone_number("233201234567") is False  # Missing +
    
    def test_wrong_country_code(self):
        """Test wrong country codes"""
        assert validate_phone_number("+1234567890") is False
        assert validate_phone_number("+44201234567") is False


class TestWalletTopupValidation:
    """Test wallet top-up validation"""
    
    def test_valid_amounts(self):
        """Test valid top-up amounts"""
        valid, _ = validate_wallet_topup(10)
        assert valid is True
        
        valid, _ = validate_wallet_topup(50)
        assert valid is True
        
        valid, _ = validate_wallet_topup(1000)
        assert valid is True
    
    def test_amount_too_low(self):
        """Test amounts below minimum"""
        valid, error = validate_wallet_topup(5)
        assert valid is False
        assert "minimum" in error.lower()
        
        valid, error = validate_wallet_topup(0)
        assert valid is False
    
    def test_amount_too_high(self):
        """Test amounts above maximum"""
        valid, error = validate_wallet_topup(1001)
        assert valid is False
        assert "maximum" in error.lower()
        
        valid, error = validate_wallet_topup(5000)
        assert valid is False


class TestPaginationValidation:
    """Test pagination validation"""
    
    def test_valid_pagination(self):
        """Test valid pagination parameters"""
        valid, error, page, page_size = validate_pagination(1, 20)
        assert valid is True
        assert page == 1
        assert page_size == 20
    
    def test_invalid_page_number(self):
        """Test invalid page numbers"""
        valid, error, _, _ = validate_pagination(0, 20)
        assert valid is False
        
        valid, error, _, _ = validate_pagination(-1, 20)
        assert valid is False
    
    def test_invalid_page_size(self):
        """Test invalid page sizes"""
        valid, error, _, _ = validate_pagination(1, 0)
        assert valid is False
        
        valid, error, _, _ = validate_pagination(1, 101)
        assert valid is False
    
    def test_default_values(self):
        """Test that defaults are applied"""
        valid, error, page, page_size = validate_pagination(1, 20)
        assert valid is True
        assert isinstance(page, int)
        assert isinstance(page_size, int)


class TestSwapRequestValidation:
    """Test swap request validation"""
    
    def test_valid_swap_request(self):
        """Test valid swap request"""
        request = {
            'bike_id': 'BIKE-123',
            'station_id': 'STN-456'
        }
        valid, error = validate_swap_request(request)
        assert valid is True
    
    def test_missing_bike_id(self):
        """Test missing bike_id"""
        request = {'station_id': 'STN-456'}
        valid, error = validate_swap_request(request)
        assert valid is False
        assert 'bike_id' in error.lower()
    
    def test_missing_station_id(self):
        """Test missing station_id"""
        request = {'bike_id': 'BIKE-123'}
        valid, error = validate_swap_request(request)
        assert valid is False
        assert 'station_id' in error.lower()
    
    def test_empty_values(self):
        """Test empty string values"""
        request = {'bike_id': '', 'station_id': 'STN-456'}
        valid, error = validate_swap_request(request)
        assert valid is False


class TestStationDataValidation:
    """Test station data validation"""
    
    def test_valid_station_data(self):
        """Test valid station data"""
        station = {
            'name': 'Test Station',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'address': '123 Test St',
            'city': 'Accra',
            'total_capacity': 10
        }
        valid, error = validate_station_data(station)
        assert valid is True
    
    def test_missing_required_fields(self):
        """Test missing required fields"""
        station = {
            'name': 'Test Station',
            'latitude': 5.6037
            # Missing other required fields
        }
        valid, error = validate_station_data(station)
        assert valid is False
    
    def test_invalid_coordinates(self):
        """Test invalid coordinates in station data"""
        station = {
            'name': 'Test Station',
            'latitude': 100,  # Invalid
            'longitude': -0.1870,
            'address': '123 Test St',
            'city': 'Accra',
            'total_capacity': 10
        }
        valid, error = validate_station_data(station)
        assert valid is False
    
    def test_invalid_capacity(self):
        """Test invalid capacity"""
        station = {
            'name': 'Test Station',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'address': '123 Test St',
            'city': 'Accra',
            'total_capacity': 0  # Invalid
        }
        valid, error = validate_station_data(station)
        assert valid is False


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
