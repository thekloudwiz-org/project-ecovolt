-- EcoVolt Application Seed Data
-- Sample data for testing and demo purposes

-- Sample users
INSERT INTO users (user_id, email, name, phone, wallet_balance, subscription, total_swaps, created_at) VALUES
('user-001', 'john.doe@example.com', 'John Doe', '+233241234567', 150.00, 'basic', 5, NOW() - INTERVAL '30 days'),
('user-002', 'jane.smith@example.com', 'Jane Smith', '+233242345678', 200.00, 'premium', 12, NOW() - INTERVAL '60 days'),
('user-003', 'kwame.mensah@example.com', 'Kwame Mensah', '+233243456789', 75.50, 'basic', 3, NOW() - INTERVAL '15 days'),
('user-004', 'ama.asante@example.com', 'Ama Asante', '+233244567890', 300.00, 'premium', 20, NOW() - INTERVAL '90 days'),
('user-005', 'kofi.owusu@example.com', 'Kofi Owusu', '+233245678901', 50.00, 'basic', 1, NOW() - INTERVAL '5 days')
ON CONFLICT (user_id) DO NOTHING;

-- Sample stations in Accra, Ghana
INSERT INTO stations (station_id, name, latitude, longitude, address, city, status, total_capacity, operating_hours, amenities, pricing, created_at) VALUES
('STN-001', 'Accra Mall Station', 5.6037, -0.1870, 'Accra Mall, Tetteh Quarshie Interchange', 'Accra', 'active', 20, 
 '{"open": "06:00", "close": "22:00"}', '["parking", "waiting_area", "wifi", "security"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '180 days'),

('STN-002', 'Osu Oxford Street Station', 5.5558, -0.1821, 'Oxford Street, Osu', 'Accra', 'active', 15,
 '{"open": "07:00", "close": "23:00"}', '["parking", "wifi"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '150 days'),

('STN-003', 'Tema Community 1 Station', 5.6698, -0.0166, 'Community 1, Tema', 'Tema', 'active', 25,
 '{"open": "06:00", "close": "22:00"}', '["parking", "waiting_area", "security", "restroom"]', '{"swap_fee": 4.5, "currency": "GHS"}', NOW() - INTERVAL '120 days'),

('STN-004', 'Legon Campus Station', 5.6519, -0.1873, 'University of Ghana, Legon', 'Accra', 'active', 18,
 '{"open": "06:00", "close": "21:00"}', '["parking", "wifi", "waiting_area"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '100 days'),

('STN-005', 'Madina Market Station', 5.6833, -0.1667, 'Madina Market Area', 'Accra', 'active', 22,
 '{"open": "05:30", "close": "22:30"}', '["parking", "security"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '90 days'),

('STN-006', 'Spintex Road Station', 5.6333, -0.1167, 'Spintex Road, Near Baatsona', 'Accra', 'active', 20,
 '{"open": "06:00", "close": "22:00"}', '["parking", "waiting_area", "wifi"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '75 days'),

('STN-007', 'Kaneshie Station', 5.5667, -0.2333, 'Kaneshie Market Area', 'Accra', 'active', 16,
 '{"open": "06:00", "close": "21:00"}', '["parking", "security"]', '{"swap_fee": 5.0, "currency": "GHS"}', NOW() - INTERVAL '60 days'),

('STN-008', 'East Legon Station', 5.6333, -0.1500, 'East Legon, A&C Mall', 'Accra', 'active', 18,
 '{"open": "07:00", "close": "22:00"}', '["parking", "waiting_area", "wifi", "restroom"]', '{"swap_fee": 5.5, "currency": "GHS"}', NOW() - INTERVAL '45 days')
ON CONFLICT (station_id) DO NOTHING;

-- Sample bikes
INSERT INTO bikes (bike_id, user_id, battery_id, model, status, battery_level, odometer, last_swap, created_at) VALUES
('BIKE-001', 'user-001', 'BAT-101', 'EcoVolt X1', 'active', 85, 1250.5, NOW() - INTERVAL '2 days', NOW() - INTERVAL '30 days'),
('BIKE-002', 'user-002', 'BAT-102', 'EcoVolt X1', 'active', 92, 2340.8, NOW() - INTERVAL '1 day', NOW() - INTERVAL '60 days'),
('BIKE-003', 'user-003', 'BAT-103', 'EcoVolt X2', 'active', 45, 567.3, NOW() - INTERVAL '5 days', NOW() - INTERVAL '15 days'),
('BIKE-004', 'user-004', 'BAT-104', 'EcoVolt X2', 'active', 78, 4521.2, NOW() - INTERVAL '3 days', NOW() - INTERVAL '90 days'),
('BIKE-005', 'user-005', 'BAT-105', 'EcoVolt X1', 'active', 65, 234.7, NOW() - INTERVAL '4 days', NOW() - INTERVAL '5 days'),
('BIKE-006', NULL, 'BAT-106', 'EcoVolt X1', 'active', 100, 0.0, NULL, NOW() - INTERVAL '1 day'),
('BIKE-007', NULL, 'BAT-107', 'EcoVolt X2', 'active', 100, 0.0, NULL, NOW() - INTERVAL '1 day'),
('BIKE-008', NULL, 'BAT-108', 'EcoVolt X1', 'maintenance', 0, 1890.5, NOW() - INTERVAL '10 days', NOW() - INTERVAL '45 days')
ON CONFLICT (bike_id) DO NOTHING;

-- Sample completed swaps (historical data)
INSERT INTO swaps (swap_id, user_id, bike_id, station_id, old_battery_id, new_battery_id, cost, status, duration_seconds, created_at, completed_at) VALUES
('SWAP-001', 'user-001', 'BIKE-001', 'STN-001', 'BAT-001', 'BAT-101', 5.0, 'completed', 180, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days' + INTERVAL '3 minutes'),
('SWAP-002', 'user-002', 'BIKE-002', 'STN-002', 'BAT-002', 'BAT-102', 5.0, 'completed', 165, NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days' + INTERVAL '2 minutes 45 seconds'),
('SWAP-003', 'user-001', 'BIKE-001', 'STN-003', 'BAT-101', 'BAT-103', 4.5, 'completed', 195, NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days' + INTERVAL '3 minutes 15 seconds'),
('SWAP-004', 'user-003', 'BIKE-003', 'STN-001', 'BAT-003', 'BAT-104', 5.0, 'completed', 210, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days' + INTERVAL '3 minutes 30 seconds'),
('SWAP-005', 'user-004', 'BIKE-004', 'STN-004', 'BAT-004', 'BAT-105', 5.0, 'completed', 175, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days' + INTERVAL '2 minutes 55 seconds'),
('SWAP-006', 'user-002', 'BIKE-002', 'STN-005', 'BAT-102', 'BAT-106', 5.0, 'completed', 188, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days' + INTERVAL '3 minutes 8 seconds'),
('SWAP-007', 'user-001', 'BIKE-001', 'STN-001', 'BAT-103', 'BAT-107', 5.0, 'completed', 192, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days' + INTERVAL '3 minutes 12 seconds'),
('SWAP-008', 'user-004', 'BIKE-004', 'STN-006', 'BAT-105', 'BAT-108', 5.0, 'completed', 168, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '2 minutes 48 seconds'),
('SWAP-009', 'user-005', 'BIKE-005', 'STN-007', 'BAT-005', 'BAT-109', 5.0, 'completed', 205, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '3 minutes 25 seconds'),
('SWAP-010', 'user-002', 'BIKE-002', 'STN-002', 'BAT-106', 'BAT-110', 5.0, 'completed', 178, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '2 minutes 58 seconds')
ON CONFLICT (swap_id) DO NOTHING;

-- Sample wallet transactions
INSERT INTO wallet_transactions (transaction_id, user_id, type, amount, balance_after, reference, created_at) VALUES
('TXN-001', 'user-001', 'topup', 200.00, 200.00, 'PAY-001', NOW() - INTERVAL '30 days'),
('TXN-002', 'user-001', 'swap', -5.00, 195.00, 'SWAP-001', NOW() - INTERVAL '28 days'),
('TXN-003', 'user-002', 'topup', 250.00, 250.00, 'PAY-002', NOW() - INTERVAL '60 days'),
('TXN-004', 'user-002', 'swap', -5.00, 245.00, 'SWAP-002', NOW() - INTERVAL '25 days'),
('TXN-005', 'user-001', 'swap', -4.50, 190.50, 'SWAP-003', NOW() - INTERVAL '20 days'),
('TXN-006', 'user-003', 'topup', 100.00, 100.00, 'PAY-003', NOW() - INTERVAL '15 days'),
('TXN-007', 'user-003', 'swap', -5.00, 95.00, 'SWAP-004', NOW() - INTERVAL '15 days'),
('TXN-008', 'user-004', 'topup', 350.00, 350.00, 'PAY-004', NOW() - INTERVAL '90 days'),
('TXN-009', 'user-004', 'swap', -5.00, 345.00, 'SWAP-005', NOW() - INTERVAL '12 days'),
('TXN-010', 'user-002', 'swap', -5.00, 240.00, 'SWAP-006', NOW() - INTERVAL '10 days'),
('TXN-011', 'user-001', 'swap', -5.00, 185.50, 'SWAP-007', NOW() - INTERVAL '8 days'),
('TXN-012', 'user-004', 'swap', -5.00, 340.00, 'SWAP-008', NOW() - INTERVAL '6 days'),
('TXN-013', 'user-005', 'topup', 75.00, 75.00, 'PAY-005', NOW() - INTERVAL '5 days'),
('TXN-014', 'user-005', 'swap', -5.00, 70.00, 'SWAP-009', NOW() - INTERVAL '4 days'),
('TXN-015', 'user-002', 'swap', -5.00, 235.00, 'SWAP-010', NOW() - INTERVAL '2 days'),
('TXN-016', 'user-001', 'topup', 50.00, 235.50, 'PAY-006', NOW() - INTERVAL '1 day'),
('TXN-017', 'user-003', 'topup', 25.00, 120.00, 'PAY-007', NOW() - INTERVAL '12 hours')
ON CONFLICT (transaction_id) DO NOTHING;

-- Add comments
COMMENT ON TABLE users IS 'Seed data includes 5 sample users with varying wallet balances and swap history';
COMMENT ON TABLE stations IS 'Seed data includes 8 stations across Accra and Tema with realistic locations';
COMMENT ON TABLE bikes IS 'Seed data includes 8 bikes, 5 assigned to users and 3 available for assignment';
COMMENT ON TABLE swaps IS 'Seed data includes 10 completed swaps showing historical activity';
COMMENT ON TABLE wallet_transactions IS 'Seed data includes transaction history for all sample users';
