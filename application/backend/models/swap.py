"""
Swap Model
Represents a battery swap transaction
"""

from dataclasses import dataclass, asdict
from typing import Optional, Dict
from datetime import datetime
from enum import Enum


class SwapStatus(Enum):
    """Valid swap status values"""
    INITIATED = "initiated"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    FAILED = "failed"


@dataclass
class Swap:
    """Battery swap transaction"""
    
    swap_id: str
    user_id: str
    bike_id: str
    station_id: str
    old_battery_id: Optional[str]
    new_battery_id: str
    cost: float
    status: str  # "initiated", "completed", "cancelled", "failed"
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_seconds: Optional[int] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.completed_at:
            data['completed_at'] = self.completed_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Swap':
        """Create from dictionary"""
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if 'completed_at' in data and isinstance(data['completed_at'], str):
            data['completed_at'] = datetime.fromisoformat(data['completed_at'])
        return cls(**data)
    
    def is_valid_status_transition(self, new_status: str) -> bool:
        """
        Validate status transition
        
        Valid transitions:
        - initiated -> completed
        - initiated -> cancelled
        - initiated -> failed
        - No transitions from completed, cancelled, or failed
        
        Requirements: 3.4, 4.3
        
        Args:
            new_status: The new status to transition to
            
        Returns:
            True if transition is valid, False otherwise
        """
        # Define valid transitions
        valid_transitions = {
            SwapStatus.INITIATED.value: [
                SwapStatus.COMPLETED.value,
                SwapStatus.CANCELLED.value,
                SwapStatus.FAILED.value
            ],
            SwapStatus.COMPLETED.value: [],  # Terminal state
            SwapStatus.CANCELLED.value: [],  # Terminal state
            SwapStatus.FAILED.value: []      # Terminal state
        }
        
        # Check if current status exists in valid transitions
        if self.status not in valid_transitions:
            return False
        
        # Check if new status is in the list of valid transitions
        return new_status in valid_transitions[self.status]
    
    def calculate_duration(self) -> Optional[int]:
        """
        Calculate swap duration in seconds
        
        Requirements: 4.3
        
        Returns:
            Duration in seconds if both timestamps exist, None otherwise
        """
        if self.created_at and self.completed_at:
            delta = self.completed_at - self.created_at
            return int(delta.total_seconds())
        return None
    
    def is_completed(self) -> bool:
        """Check if swap is completed"""
        return self.status == SwapStatus.COMPLETED.value
    
    def is_initiated(self) -> bool:
        """Check if swap is in initiated state"""
        return self.status == SwapStatus.INITIATED.value
    
    def can_be_completed(self) -> bool:
        """Check if swap can be completed (must be in initiated state)"""
        return self.is_initiated()


@dataclass
class SwapHistoryEntry:
    """Swap history entry with additional station information"""
    
    swap_id: str
    user_id: str
    bike_id: str
    station_id: str
    station_name: str
    station_address: str
    old_battery_id: Optional[str]
    new_battery_id: str
    cost: float
    status: str
    created_at: datetime
    completed_at: Optional[datetime] = None
    duration_seconds: Optional[int] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        data['created_at'] = self.created_at.isoformat()
        if self.completed_at:
            data['completed_at'] = self.completed_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'SwapHistoryEntry':
        """Create from dictionary"""
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if 'completed_at' in data and isinstance(data['completed_at'], str):
            data['completed_at'] = datetime.fromisoformat(data['completed_at'])
        return cls(**data)
