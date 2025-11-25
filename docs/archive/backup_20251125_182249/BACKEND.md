# EcoVolt Backend Documentation

## Overview

The EcoVolt backend is a serverless API built with Python 3.11, AWS Lambda, and API Gateway. It provides 38 REST API endpoints for authentication, station management, battery swaps, wallet operations, and administrative functions.

**Base URL**: `https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1`

## Table of Contents

- [Architecture](#architecture)
- [API Endpoints](#api-endpoints)
- [Authentication](#authentication)
- [Data Models](#data-models)
- [Database Schema](#database-schema)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Deployment](#deployment)

## Architecture

### Components

```
API Gateway → Lambda Authorizer (JWT validation)
    ↓
Lambda Functions:
├── auth_handler.py      # Authentication endpoints
├── api_handler.py       # Main API router
└── iot_processor.py     # IoT telemetry processing

Database Layer:
├── RDS PostgreSQL       # Relational data (users, stations, swaps)
├── DynamoDB            # Telemetry data (bike/station real-time data)
└── ElastiCache Redis   # Caching layer

External Services:
├── AWS Cognito         # User authentication
├── AWS SNS             # Push notifications
└── AWS IoT Core        # Device connectivity
```

### Request Flow

```
Client → CloudFront → API Gateway → Lambda Authorizer
                                         ↓
                                    Lambda Function
                                         ↓
                                    ┌────┴────┐
                                    │         │
                                   RDS    DynamoDB
                                    │         │
                                    └────┬────┘
                                         ↓
                                    Response
```

## API Endpoints

### Authentication (4 endpoints)

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "phone": "+233XXXXXXXXX"
}
```

**Response**:
```json
{
  "message": "User registered successfully",
  "user_id": "uuid"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGc...",
  "id_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 86400
}
```

#### Confirm Email
```http
POST /auth/confirm
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}
```

#### Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGc..."
}
```

### Stations (5 endpoints)

#### Get Nearby Stations
```http
GET /stations/nearby?latitude=5.6037&longitude=-0.187&radius=10
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "stations": [
    {
      "id": "station-001",
      "name": "Accra Central Station",
      "address": "123 Independence Ave",
      "city": "Accra",
      "latitude": 5.6037,
      "longitude": -0.187,
      "distance": 2.5,
      "availableBatteries": 8,
      "totalCapacity": 20,
      "swapCost": 15.00,
      "operatingHours": "24/7",
      "status": "active"
    }
  ]
}
```

#### Get Station Details
```http
GET /stations/{station_id}
Authorization: Bearer {access_token}
```

#### List All Stations
```http
GET /stations
Authorization: Bearer {access_token}
```

#### Get Station Availability
```http
GET /stations/{station_id}/availability
Authorization: Bearer {access_token}
```

### Swaps (4 endpoints)

#### Initiate Swap
```http
POST /swaps
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "bike_id": "BIKE001",
  "station_id": "station-001"
}
```

**Validations**:
- User owns the bike
- Station has available batteries
- User has sufficient wallet balance
- Bike is not already in a swap

**Response**:
```json
{
  "swap": {
    "id": "swap-001",
    "userId": "user-001",
    "bikeId": "BIKE001",
    "stationId": "station-001",
    "oldBatteryId": "BAT-OLD-001",
    "newBatteryId": "BAT-NEW-001",
    "cost": 15.00,
    "status": "initiated",
    "initiatedAt": "2024-01-15T10:30:00Z"
  },
  "reservedBatteryId": "BAT-NEW-001",
  "message": "Swap initiated successfully"
}
```

#### Complete Swap
```http
PUT /swaps/{swap_id}/complete
Authorization: Bearer {access_token}
```

**Actions**:
- Updates swap status to "completed"
- Deducts cost from wallet
- Creates wallet transaction
- Updates bike battery ID
- Triggers notification

#### Get Swap Status
```http
GET /swaps/{swap_id}
Authorization: Bearer {access_token}
```

#### Get Swap History
```http
GET /swaps/history?page=1&page_size=20
Authorization: Bearer {access_token}
```

### Wallet (3 endpoints)

#### Get Wallet Balance
```http
GET /wallet
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "wallet": {
    "balance": 150.50,
    "currency": "GHS",
    "lastUpdated": "2024-01-15T10:00:00Z"
  }
}
```

#### Initiate Top-Up
```http
POST /wallet/topup
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "amount": 100.00,
  "payment_method": "mtn_momo",
  "phone_number": "+233XXXXXXXXX"
}
```

**Supported Providers**:
- `mtn_momo` - MTN Mobile Money
- `telecel_cash` - Telecel Cash
- `airteltigo_money` - AirtelTigo Money

**Amount Limits**: 10.00 - 1000.00 GHS

#### Get Transaction History
```http
GET /wallet/transactions?page=1&page_size=20
Authorization: Bearer {access_token}
```

### Bikes (1 endpoint)

#### Get Bike Details
```http
GET /bikes/{bike_id}
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "bike": {
    "id": "BIKE001",
    "model": "EcoVolt E-Moto 2024",
    "batteryId": "BAT-001",
    "batteryLevel": 85,
    "status": "active",
    "latitude": 5.6037,
    "longitude": -0.187,
    "odometer": 1250.5
  },
  "telemetry": {
    "batteryLevel": 85,
    "speed": 0,
    "temperature": 28,
    "timestamp": "2024-01-15T10:30:00Z",
    "isStale": false
  }
}
```

**Staleness**: Telemetry older than 5 minutes is marked as stale.

### Profile (2 endpoints)

#### Get User Profile
```http
GET /profile
Authorization: Bearer {access_token}
```

#### Update Profile
```http
PUT /profile
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "John Updated",
  "phone": "+233YYYYYYYYY"
}
```

**Immutable Fields**: `email`, `user_id` cannot be modified

### Notifications (2 endpoints)

#### Get Notifications
```http
GET /notifications
Authorization: Bearer {access_token}
```

#### Mark as Read
```http
PUT /notifications/{notification_id}/read
Authorization: Bearer {access_token}
```

### Admin Endpoints (18 endpoints)

All admin endpoints require the user to be in the `admin` Cognito group.

#### Dashboard
```http
GET /admin/dashboard
Authorization: Bearer {admin_access_token}
```

**Response**:
```json
{
  "totalSwapsToday": 125,
  "totalRevenueToday": 1875.00,
  "activeRiders": 450,
  "totalStations": 15,
  "swapTrend": [
    { "date": "2024-01-09", "count": 98 },
    { "date": "2024-01-10", "count": 105 }
  ],
  "topStations": [
    {
      "id": "station-001",
      "name": "Accra Central",
      "swapCount": 45,
      "revenue": 675.00
    }
  ]
}
```

#### Analytics
```http
GET /admin/analytics?start_date=2024-01-01&end_date=2024-01-31
GET /admin/analytics/stations
GET /admin/analytics/revenue
GET /admin/analytics/batteries
```

#### Station Management
```http
GET /admin/stations?page=1&page_size=20
POST /admin/stations
PUT /admin/stations/{station_id}
DELETE /admin/stations/{station_id}
```

#### Bike Fleet Management
```http
GET /admin/bikes?page=1&page_size=20
POST /admin/bikes
PUT /admin/bikes/{bike_id}
PUT /admin/bikes/{bike_id}/assign
```

#### User Management
```http
GET /admin/users?page=1&page_size=20
GET /admin/users/{user_id}
PUT /admin/users/{user_id}/wallet
```

## Authentication

### JWT Token Structure

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "cognito:groups": ["user"],
  "exp": 1705329600,
  "iat": 1705243200
}
```

### Token Expiration
- **Access Token**: 24 hours
- **ID Token**: 24 hours
- **Refresh Token**: 30 days

### Authorization Header
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Data Models

### User
```python
class User:
    user_id: str
    email: str
    name: str
    phone: str
    wallet_balance: Decimal
    created_at: datetime
    updated_at: datetime
```

### Station
```python
class Station:
    station_id: str
    name: str
    address: str
    city: str
    latitude: Decimal
    longitude: Decimal
    capacity: int
    swap_cost: Decimal
    operating_hours: str
    status: str  # active, inactive, maintenance
    created_at: datetime
    updated_at: datetime
```

### Bike
```python
class Bike:
    bike_id: str
    user_id: str | None
    model: str
    battery_id: str
    status: str  # active, inactive, maintenance
    created_at: datetime
    updated_at: datetime
```

### Swap
```python
class Swap:
    swap_id: str
    user_id: str
    bike_id: str
    station_id: str
    old_battery_id: str
    new_battery_id: str
    cost: Decimal
    status: str  # initiated, completed, failed, cancelled
    initiated_at: datetime
    completed_at: datetime | None
```

### WalletTransaction
```python
class WalletTransaction:
    transaction_id: str
    user_id: str
    type: str  # topup, swap, refund, adjustment
    amount: Decimal
    balance_before: Decimal
    balance_after: Decimal
    reference: str
    status: str  # pending, completed, failed
    created_at: datetime
```

## Database Schema

### Tables

#### users
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    wallet_balance DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### stations
```sql
CREATE TABLE stations (
    station_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    capacity INTEGER NOT NULL,
    swap_cost DECIMAL(10, 2) NOT NULL,
    operating_hours VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);
```

#### bikes
```sql
CREATE TABLE bikes (
    bike_id VARCHAR(50) PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    model VARCHAR(255) NOT NULL,
    battery_id VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### swaps
```sql
CREATE TABLE swaps (
    swap_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) NOT NULL,
    bike_id VARCHAR(50) REFERENCES bikes(bike_id) NOT NULL,
    station_id VARCHAR(50) REFERENCES stations(station_id) NOT NULL,
    old_battery_id VARCHAR(50),
    new_battery_id VARCHAR(50),
    cost DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'initiated',
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);
```

#### wallet_transactions
```sql
CREATE TABLE wallet_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) NOT NULL,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    reference VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Indexes

```sql
-- Location-based queries
CREATE INDEX idx_stations_location ON stations(latitude, longitude);
CREATE INDEX idx_stations_city ON stations(city);

-- User relationships
CREATE INDEX idx_bikes_user_id ON bikes(user_id);
CREATE INDEX idx_swaps_user_id ON swaps(user_id);
CREATE INDEX idx_transactions_user_id ON wallet_transactions(user_id);

-- Time-based queries
CREATE INDEX idx_swaps_initiated_at ON swaps(initiated_at);
CREATE INDEX idx_transactions_created_at ON wallet_transactions(created_at);

-- Status queries
CREATE INDEX idx_stations_status ON stations(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_bikes_status ON bikes(status);
CREATE INDEX idx_swaps_status ON swaps(status);
```

## Development Setup

### Prerequisites

```bash
# Install Python 3.11
brew install python@3.11

# Install dependencies
cd application/backend
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### Local Development

```bash
# Set environment variables
export AWS_REGION=eu-central-1
export DB_HOST=localhost
export DB_NAME=ecovolt
export DB_USER=ecovolt_admin
export DB_PASSWORD=password
export COGNITO_USER_POOL_ID=eu-central-1_xxxxx
export COGNITO_CLIENT_ID=xxxxx

# Run local PostgreSQL
docker run -d \
  --name ecovolt-postgres \
  -e POSTGRES_DB=ecovolt \
  -e POSTGRES_USER=ecovolt_admin \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15

# Run migrations
psql -h localhost -U ecovolt_admin -d ecovolt -f migrations/001_initial_schema.sql
psql -h localhost -U ecovolt_admin -d ecovolt -f migrations/002_add_indexes.sql
psql -h localhost -U ecovolt_admin -d ecovolt -f migrations/003_seed_data.sql

# Run tests
pytest tests/ -v
```

### Project Structure

```
application/backend/
├── api/                    # API endpoint handlers
│   ├── auth.py            # Authentication endpoints
│   ├── users.py           # User profile & wallet
│   ├── swaps.py           # Swap operations
│   ├── bikes.py           # Bike operations
│   ├── stations.py        # Station operations
│   └── admin.py           # Admin endpoints
├── models/                 # Data models
│   ├── swap.py
│   ├── payment.py
│   ├── bike.py
│   └── station.py
├── utils/                  # Utilities
│   ├── db.py              # Database helpers
│   ├── validators.py      # Input validation
│   ├── auth.py            # Auth utilities
│   └── notifications.py   # SNS integration
├── functions/              # Lambda handlers
│   ├── auth_handler.py
│   ├── api_handler.py
│   └── iot_processor.py
├── migrations/             # Database migrations
│   ├── 001_initial_schema.sql
│   ├── 002_add_indexes.sql
│   └── 003_seed_data.sql
├── tests/                  # Test suite
├── requirements.txt        # Dependencies
└── requirements-dev.txt    # Dev dependencies
```

## Testing

### Unit Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_swaps.py -v

# Run with coverage
pytest tests/ --cov=. --cov-report=html
```

### Integration Tests

```bash
# Test against deployed API
export API_URL=https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1
python tests/integration/test_api.py
```

### Load Testing

```bash
# Install locust
pip install locust

# Run load test
locust -f tests/load/locustfile.py --host=$API_URL
```

## Deployment

### Package Lambda Functions

```bash
cd application/backend
./scripts/package_lambdas.sh
```

This creates:
- `auth_handler.zip`
- `api_handler.zip`
- `iot_processor.zip`

### Deploy via Terraform

```bash
terraform apply -target=module.compute
```

### Manual Deployment

```bash
# Update Lambda function
aws lambda update-function-code \
  --function-name ecovolt-api-handler \
  --zip-file fileb://api_handler.zip

# Publish new version
aws lambda publish-version \
  --function-name ecovolt-api-handler

# Update alias
aws lambda update-alias \
  --function-name ecovolt-api-handler \
  --name production \
  --function-version $LATEST
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_INPUT` | 400 | Invalid request parameters |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict or state error |
| `INSUFFICIENT_BALANCE` | 400 | Wallet balance too low |
| `BATTERY_UNAVAILABLE` | 400 | No batteries available at station |
| `SWAP_IN_PROGRESS` | 409 | Bike already in active swap |
| `INTERNAL_ERROR` | 500 | Server-side error |

## Rate Limiting

- **User endpoints**: 100 requests/minute
- **Admin endpoints**: 200 requests/minute

## Support

- **API Issues**: api-support@ecovolt.com
- **Documentation**: See [docs/](../docs/)

---

**Last Updated**: November 2024  
**API Version**: 1.0.0

