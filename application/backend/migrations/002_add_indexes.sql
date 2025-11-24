-- EcoVolt Application Indexes Migration
-- Creates indexes for performance optimization

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Stations table indexes
CREATE INDEX IF NOT EXISTS idx_stations_location ON stations(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_stations_status ON stations(status);
CREATE INDEX IF NOT EXISTS idx_stations_city ON stations(city);
CREATE INDEX IF NOT EXISTS idx_stations_created_at ON stations(created_at);

-- Bikes table indexes
CREATE INDEX IF NOT EXISTS idx_bikes_user_id ON bikes(user_id);
CREATE INDEX IF NOT EXISTS idx_bikes_status ON bikes(status);
CREATE INDEX IF NOT EXISTS idx_bikes_battery_id ON bikes(battery_id);
CREATE INDEX IF NOT EXISTS idx_bikes_created_at ON bikes(created_at);

-- Swaps table indexes
CREATE INDEX IF NOT EXISTS idx_swaps_user_id ON swaps(user_id);
CREATE INDEX IF NOT EXISTS idx_swaps_bike_id ON swaps(bike_id);
CREATE INDEX IF NOT EXISTS idx_swaps_station_id ON swaps(station_id);
CREATE INDEX IF NOT EXISTS idx_swaps_status ON swaps(status);
CREATE INDEX IF NOT EXISTS idx_swaps_created_at ON swaps(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_swaps_user_created ON swaps(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_swaps_station_created ON swaps(station_id, created_at DESC);

-- Wallet Transactions table indexes
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_created ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_reference ON wallet_transactions(reference);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_swaps_user_status_created ON swaps(user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bikes_user_status ON bikes(user_id, status);

-- Add comments
COMMENT ON INDEX idx_stations_location IS 'Supports nearby station queries using Haversine formula';
COMMENT ON INDEX idx_swaps_user_created IS 'Supports user swap history queries with pagination';
COMMENT ON INDEX idx_wallet_transactions_user_created IS 'Supports user transaction history queries with pagination';
