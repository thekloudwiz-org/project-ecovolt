"""
Payment and Wallet Transaction Models
Represents payment transactions and wallet operations
"""

from dataclasses import dataclass, asdict
from typing import Optional, Dict
from datetime import datetime
from enum import Enum


class PaymentStatus(Enum):
    """Valid payment status values"""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TransactionType(Enum):
    """Valid wallet transaction types"""
    TOPUP = "topup"
    SWAP = "swap"
    REFUND = "refund"
    ADJUSTMENT = "adjustment"


@dataclass
class Payment:
    """Payment transaction for wallet top-ups"""
    
    payment_id: str
    user_id: str
    amount: float
    currency: str  # "GHS"
    payment_method: str  # "mobile_money", "card", etc.
    provider: Optional[str]  # "MTN", "Telecel", "AirtelTigo"
    provider_reference: Optional[str]  # External payment reference
    status: str  # "pending", "processing", "completed", "failed", "cancelled"
    metadata: Optional[Dict] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.updated_at:
            data['updated_at'] = self.updated_at.isoformat()
        if self.completed_at:
            data['completed_at'] = self.completed_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Payment':
        """Create from dictionary"""
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if 'updated_at' in data and isinstance(data['updated_at'], str):
            data['updated_at'] = datetime.fromisoformat(data['updated_at'])
        if 'completed_at' in data and isinstance(data['completed_at'], str):
            data['completed_at'] = datetime.fromisoformat(data['completed_at'])
        return cls(**data)
    
    def is_valid_status_transition(self, new_status: str) -> bool:
        """
        Validate payment status transition
        
        Valid transitions:
        - pending -> processing
        - pending -> cancelled
        - processing -> completed
        - processing -> failed
        - No transitions from completed, failed, or cancelled
        
        Requirements: 6.4
        
        Args:
            new_status: The new status to transition to
            
        Returns:
            True if transition is valid, False otherwise
        """
        valid_transitions = {
            PaymentStatus.PENDING.value: [
                PaymentStatus.PROCESSING.value,
                PaymentStatus.CANCELLED.value
            ],
            PaymentStatus.PROCESSING.value: [
                PaymentStatus.COMPLETED.value,
                PaymentStatus.FAILED.value
            ],
            PaymentStatus.COMPLETED.value: [],  # Terminal state
            PaymentStatus.FAILED.value: [],     # Terminal state
            PaymentStatus.CANCELLED.value: []   # Terminal state
        }
        
        if self.status not in valid_transitions:
            return False
        
        return new_status in valid_transitions[self.status]
    
    def is_completed(self) -> bool:
        """Check if payment is completed"""
        return self.status == PaymentStatus.COMPLETED.value
    
    def is_failed(self) -> bool:
        """Check if payment failed"""
        return self.status == PaymentStatus.FAILED.value
    
    def is_pending(self) -> bool:
        """Check if payment is pending"""
        return self.status == PaymentStatus.PENDING.value


@dataclass
class WalletTransaction:
    """Wallet transaction record"""
    
    transaction_id: str
    user_id: str
    type: str  # "topup", "swap", "refund", "adjustment"
    amount: float  # Positive for credits, negative for debits
    balance_after: float
    reference: Optional[str]  # Reference to related entity (swap_id, payment_id, etc.)
    metadata: Optional[Dict] = None
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        data = asdict(self)
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'WalletTransaction':
        """Create from dictionary"""
        if 'created_at' in data and isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        return cls(**data)
    
    def is_valid_type(self) -> bool:
        """
        Validate transaction type
        
        Requirements: 6.4
        
        Returns:
            True if type is valid, False otherwise
        """
        valid_types = [t.value for t in TransactionType]
        return self.type in valid_types
    
    def is_credit(self) -> bool:
        """Check if transaction is a credit (positive amount)"""
        return self.amount > 0
    
    def is_debit(self) -> bool:
        """Check if transaction is a debit (negative amount)"""
        return self.amount < 0
    
    def get_display_amount(self) -> str:
        """Get formatted amount for display"""
        sign = "+" if self.amount >= 0 else ""
        return f"{sign}{self.amount:.2f} GHS"


@dataclass
class MobileMoneyRequest:
    """Mobile Money payment request"""
    
    phone_number: str
    amount: float
    provider: str  # "MTN", "Telecel", "AirtelTigo"
    reference: str
    callback_url: Optional[str] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return asdict(self)
    
    def validate(self) -> tuple[bool, Optional[str]]:
        """
        Validate mobile money request
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not self.phone_number or not self.phone_number.startswith('+233'):
            return False, "Invalid Ghanaian phone number"
        
        if self.amount <= 0:
            return False, "Amount must be greater than zero"
        
        if self.amount < 10 or self.amount > 1000:
            return False, "Amount must be between 10 and 1000 GHS"
        
        valid_providers = ["MTN", "Telecel", "AirtelTigo"]
        if self.provider not in valid_providers:
            return False, f"Invalid provider. Must be one of: {', '.join(valid_providers)}"
        
        return True, None
