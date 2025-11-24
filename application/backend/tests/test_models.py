"""
Test data models
"""

import pytest
from datetime import datetime, timedelta
from models.swap import Swap, SwapStatus
from models.bike import Bike, BikeTelemetry
from models.payment import Payment, PaymentStatus, WalletTransaction


class TestSwapModel:
    """Test Swap model"""
    
    def test_swap_creation(self):
        """Test creating a swap"""
        swap = Swap(
            swap_id="SWAP-123",
            user_id="USER-456",
            bike_id="BIKE-789",
            station_id="STN-012",
            old_battery_id="BAT-OLD",
            new_battery_id="BAT-NEW",
            cost=5.0,
            status=SwapStatus.INITIATED
        )
        
        assert swap.swap_id == "SWAP-123"
        assert swap.status == SwapStatus.INITIATED
        assert swap.cost == 5.0
    
    def test_swap_status_enum(self):
        """Test swap status enum values"""
        assert SwapStatus.INITIATED.value == "initiated"
        assert SwapStatus.COMPLETED.value == "completed"
        assert SwapStatus.FAILED.value == "failed"
    
    def test_swap_duration_calculation(self):
        """Test swap duration calculation"""
        created_at = datetime.now() - timedelta(minutes=5)
        completed_at = datetime.now()
        
        duration = int((completed_at - created_at).total_seconds())
        assert 290 <= duration <= 310  # ~300 seconds with tolerance


class TestBikeModel:
    """Test Bike model"""
    
    def test_bike_creation(self):
        """Test creating a bike"""
        bike = Bike(
            bike_id="BIKE-123",
            user_id="USER-456",
            battery_id="BAT-789",
            model="EcoVolt Pro",
            status="active",
            battery_level=85,
            odometer=1234.5
        )
        
        assert bike.bike_id == "BIKE-123"
        assert bike.model == "EcoVolt Pro"
        assert bike.battery_level == 85
        assert bike.odometer == 1234.5


class TestBikeTelemetry:
    """Test Bike Telemetry"""
    
    def test_telemetry_creation(self):
        """Test creating telemetry data"""
        telemetry = BikeTelemetry(
            bike_id="BIKE-123",
            timestamp=datetime.now(),
            battery_level=75,
            location={'lat': 5.6037, 'lng': -0.1870},
            speed=25.5,
            odometer=1500.0,
            temperature=28.5
        )
        
        assert telemetry.bike_id == "BIKE-123"
        assert telemetry.battery_level == 75
        assert telemetry.speed == 25.5
    
    def test_telemetry_staleness_fresh(self):
        """Test that fresh telemetry is not stale"""
        telemetry = BikeTelemetry(
            bike_id="BIKE-123",
            timestamp=datetime.now(),
            battery_level=75,
            location={'lat': 5.6037, 'lng': -0.1870}
        )
        
        assert telemetry.is_stale(max_age_minutes=5) is False
    
    def test_telemetry_staleness_old(self):
        """Test that old telemetry is stale"""
        old_timestamp = datetime.now() - timedelta(minutes=10)
        telemetry = BikeTelemetry(
            bike_id="BIKE-123",
            timestamp=old_timestamp,
            battery_level=75,
            location={'lat': 5.6037, 'lng': -0.1870}
        )
        
        assert telemetry.is_stale(max_age_minutes=5) is True
    
    def test_freshness_indicator(self):
        """Test freshness indicator"""
        # Fresh data
        fresh_telemetry = BikeTelemetry(
            bike_id="BIKE-123",
            timestamp=datetime.now(),
            battery_level=75,
            location={'lat': 5.6037, 'lng': -0.1870}
        )
        assert fresh_telemetry.get_freshness_indicator() == "fresh"
        
        # Stale data
        stale_telemetry = BikeTelemetry(
            bike_id="BIKE-123",
            timestamp=datetime.now() - timedelta(minutes=10),
            battery_level=75,
            location={'lat': 5.6037, 'lng': -0.1870}
        )
        assert stale_telemetry.get_freshness_indicator() == "stale"


class TestPaymentModel:
    """Test Payment model"""
    
    def test_payment_creation(self):
        """Test creating a payment"""
        payment = Payment(
            payment_id="PAY-123",
            user_id="USER-456",
            amount=50.0,
            payment_method="mobile_money",
            provider="MTN",
            status=PaymentStatus.PENDING
        )
        
        assert payment.payment_id == "PAY-123"
        assert payment.amount == 50.0
        assert payment.provider == "MTN"
        assert payment.status == PaymentStatus.PENDING
    
    def test_payment_status_enum(self):
        """Test payment status enum values"""
        assert PaymentStatus.PENDING.value == "pending"
        assert PaymentStatus.COMPLETED.value == "completed"
        assert PaymentStatus.FAILED.value == "failed"


class TestWalletTransaction:
    """Test Wallet Transaction model"""
    
    def test_transaction_creation(self):
        """Test creating a wallet transaction"""
        transaction = WalletTransaction(
            transaction_id="TXN-123",
            user_id="USER-456",
            type="topup",
            amount=50.0,
            balance_after=150.0,
            reference="PAY-789"
        )
        
        assert transaction.transaction_id == "TXN-123"
        assert transaction.type == "topup"
        assert transaction.amount == 50.0
        assert transaction.balance_after == 150.0
    
    def test_transaction_types(self):
        """Test different transaction types"""
        types = ["topup", "swap", "adjustment", "refund"]
        
        for txn_type in types:
            transaction = WalletTransaction(
                transaction_id=f"TXN-{txn_type}",
                user_id="USER-456",
                type=txn_type,
                amount=10.0,
                balance_after=100.0,
                reference="REF-123"
            )
            assert transaction.type == txn_type


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
