"""
Bike Model
Represents an IoT-enabled electric motorcycle
"""

from dataclasses import dataclass, asdict
from typing import Optional, Dict
from datetime import datetime


@dataclass
class Bike:
    """Electric motorcycle with IoT capabilities"""
    
    bike_id: str
    user_id: Optional[str]
    battery_id: Optional[str]
    model: str
    status: str  # "active", "inactive", "maintenance"
    battery_level: Optional[int]  # 0-100
    odometer: Optional[float]  # kilometers
    last_swap: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.last_swap:
            data['last_swap'] = self.last_swap.isoformat()
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.updated_at:
            data['updated_at'] = self.updated_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Bike':
        """Create from dictionary"""
        if 'last_swap' in data and isinstance(data['last_swap'], str):
            data['last_swap'] = datetime.fromisoformat(data['last_swap'])
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if 'updated_at' in data and isinstance(data['updated_at'], str):
            data['updated_at'] = datetime.fromisoformat(data['updated_at'])
        return cls(**data)
    
    def is_active(self) -> bool:
        """Check if bike is active"""
        return self.status == "active"
    
    def is_assigned(self) -> bool:
        """Check if bike is assigned to a user"""
        return self.user_id is not None
    
    def needs_battery_swap(self, threshold: int = 20) -> bool:
        """
        Check if bike needs battery swap
        
        Requirements: 7.2
        
        Args:
            threshold: Battery level threshold (default 20%)
            
        Returns:
            True if battery level is below threshold
        """
        if self.battery_level is None:
            return False
        return self.battery_level < threshold
    
    def get_battery_status(self) -> str:
        """
        Get battery status description
        
        Requirements: 7.2
        
        Returns:
            Battery status string
        """
        if self.battery_level is None:
            return "unknown"
        elif self.battery_level >= 80:
            return "excellent"
        elif self.battery_level >= 50:
            return "good"
        elif self.battery_level >= 20:
            return "low"
        else:
            return "critical"


@dataclass
class BikeTelemetry:
    """Real-time telemetry data from bike IoT device"""
    
    bike_id: str
    timestamp: datetime
    battery_level: int  # 0-100
    location: Dict[str, float]  # {"lat": float, "lng": float}
    speed: Optional[float] = None  # km/h
    odometer: Optional[float] = None  # kilometers
    temperature: Optional[float] = None  # celsius
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        data['timestamp'] = self.timestamp.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'BikeTelemetry':
        """Create from dictionary"""
        if 'timestamp' in data and isinstance(data['timestamp'], str):
            data['timestamp'] = datetime.fromisoformat(data['timestamp'])
        return cls(**data)
    
    def is_stale(self, max_age_minutes: int = 5) -> bool:
        """
        Check if telemetry data is stale
        
        Requirements: 7.4
        
        Args:
            max_age_minutes: Maximum age in minutes (default 5)
            
        Returns:
            True if data is older than max_age_minutes
        """
        age = datetime.now() - self.timestamp
        return age.total_seconds() > (max_age_minutes * 60)
    
    def get_freshness_indicator(self) -> str:
        """
        Get freshness indicator for telemetry
        
        Requirements: 7.4
        
        Returns:
            Freshness status string
        """
        age_seconds = (datetime.now() - self.timestamp).total_seconds()
        
        if age_seconds < 60:
            return "real-time"
        elif age_seconds < 300:  # 5 minutes
            return "recent"
        elif age_seconds < 900:  # 15 minutes
            return "stale"
        else:
            return "outdated"
