-- EcoVolt Application Initial Schema Migration
-- Creates all core tables for the application

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    wallet_balance DECIMAL(10, 2) DEFAULT 0.00,
    subscription VARCHAR(50) DEFAULT 'basic',
    total_swaps INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Stations table
CREATE TABLE IF NOT EXISTS stations (
    station_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    total_capacity INTEGER NOT NULL,
    operating_hours JSONB,
    amenities JSONB,
    pricing JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Bikes table
CREATE TABLE IF NOT EXISTS bikes (
    bike_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    battery_id VARCHAR(50),
    model VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    battery_level INTEGER,
    odometer DECIMAL(10, 2),
    last_swap TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Swaps table
CREATE TABLE IF NOT EXISTS swaps (
    swap_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    bike_id VARCHAR(50) REFERENCES bikes(bike_id) NOT NULL,
    station_id VARCHAR(50) REFERENCES stations(station_id) NOT NULL,
    old_battery_id VARCHAR(50),
    new_battery_id VARCHAR(50) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'initiated',
    duration_seconds INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Wallet Transactions table
CREATE TABLE IF NOT EXISTS wallet_transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'topup', 'swap', 'refund', 'adjustment'
    amount DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    reference VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE users IS 'EcoVolt users (riders and admins)';
COMMENT ON TABLE stations IS 'Battery swap stations';
COMMENT ON TABLE bikes IS 'Electric motorcycles registered in the system';
COMMENT ON TABLE swaps IS 'Battery swap transactions';
COMMENT ON TABLE wallet_transactions IS 'Wallet transaction history';

COMMENT ON COLUMN users.wallet_balance IS 'Current wallet balance in GHS';
COMMENT ON COLUMN users.total_swaps IS 'Total number of swaps completed by user';
COMMENT ON COLUMN stations.status IS 'Station status: active, inactive, maintenance';
COMMENT ON COLUMN bikes.status IS 'Bike status: active, inactive, maintenance';
COMMENT ON COLUMN swaps.status IS 'Swap status: initiated, completed, cancelled, failed';
COMMENT ON COLUMN wallet_transactions.type IS 'Transaction type: topup, swap, refund, adjustment';
