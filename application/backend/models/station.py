"""
Station Model
Represents a battery swap station
"""

from dataclasses import dataclass, asdict
from typing import Optional, List, Dict
from datetime import datetime


@dataclass
class Station:
    """Battery swap station"""
    
    station_id: str
    name: str
    location: Dict[str, float]  # {"lat": float, "lng": float}
    address: str
    city: str
    status: str  # "active", "inactive", "maintenance"
    available_batteries: int
    total_capacity: int
    operating_hours: Dict[str, str]  # {"open": "06:00", "close": "22:00"}
    amenities: List[str]  # ["parking", "waiting_area", "wifi"]
    pricing: Dict[str, float]  # {"swap_fee": 5.0, "currency": "GHS"}
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.updated_at:
            data['updated_at'] = self.updated_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Station':
        """Create from dictionary"""
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if 'updated_at' in data and isinstance(data['updated_at'], str):
            data['updated_at'] = datetime.fromisoformat(data['updated_at'])
        return cls(**data)
    
    def is_operational(self) -> bool:
        """Check if station is operational"""
        return self.status == "active" and self.available_batteries > 0
    
    def battery_availability_percentage(self) -> float:
        """Calculate battery availability percentage"""
        if self.total_capacity == 0:
            return 0.0
        return (self.available_batteries / self.total_capacity) * 100
    
    def distance_from(self, lat: float, lng: float) -> float:
        """
        Calculate distance from given coordinates (in km)
        Using Haversine formula
        """
        from math import radians, sin, cos, sqrt, atan2
        
        R = 6371  # Earth's radius in km
        
        lat1 = radians(lat)
        lon1 = radians(lng)
        lat2 = radians(self.location['lat'])
        lon2 = radians(self.location['lng'])
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return R * c


@dataclass
class Battery:
    """Battery unit"""
    
    battery_id: str
    station_id: Optional[str]
    bike_id: Optional[str]
    charge_level: int  # 0-100
    health: int  # 0-100
    status: str  # "available", "in_use", "charging", "maintenance"
    cycles: int  # Number of charge cycles
    last_charged: Optional[datetime] = None
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.last_charged:
            data['last_charged'] = self.last_charged.isoformat()
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        return data
    
    def is_available(self) -> bool:
        """Check if battery is available for swap"""
        return (
            self.status == "available" and
            self.charge_level >= 80 and
            self.health >= 70
        )
