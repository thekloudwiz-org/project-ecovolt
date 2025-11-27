# EcoVolt Application Design Document

## Overview

The EcoVolt Application Suite consists of three interconnected components that enable battery swapping operations for electric motorcycles in Ghana:

1. **Mobile Application (React Native)** - Rider-facing app for finding stations, performing swaps, and managing wallet
2. **Admin Portal (React Web)** - Operations dashboard for managing stations, bikes, users, and viewing analytics
3. **Backend API (Python Lambda)** - RESTful API service that processes requests and manages business logic

The system leverages AWS services including Lambda, API Gateway, RDS PostgreSQL, DynamoDB, Cognito, and IoT Core to provide a scalable, secure, and real-time platform for battery swapping operations.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Client Applications                          │
├──────────────────────────┬──────────────────────────────────────┤
│  Mobile App              │  Admin Portal                         │
│  (React Native)          │  (React Web)                          │
│  - iOS & Android         │  - Dashboard                          │
│  - Station Finder        │  - Station Management                 │
│  - Battery Swaps         │  - Fleet Management                   │
│  - Wallet                │  - Analytics                          │
└──────────┬───────────────┴──────────┬───────────────────────────┘
           │                          │
           └──────────┬───────────────┘
                      │
              ┌───────▼────────┐
              │  API Gateway   │
              │  + WAF         │
              └───────┬────────┘
                      │
              ┌───────▼────────┐
              │  Cognito       │
              │  (Auth)        │
              └───────┬────────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
    ┌────▼────┐  ┌───▼────┐  ┌───▼────┐
    │ Lambda  │  │ Lambda │  │ Lambda │
    │ (API)   │  │ (IoT)  │  │(Stream)│
    └────┬────┘  └───┬────┘  └───┬────┘
         │           │           │
    ┌────▼───────────▼───────────▼────┐
    │  RDS PostgreSQL + DynamoDB      │
    │  - Users, Stations, Swaps       │
    │  - Batteries, Telemetry         │
    └─────────────────────────────────┘
         │
    ┌────▼────────────────────────────┐
    │  IoT Core                       │
    │  - Bikes & Stations             │
    └─────────────────────────────────┘
```

### Technology Stack

**Mobile Application:**
- React Native 0.72+
- TypeScript
- React Navigation (routing)
- AWS Amplify (Auth, API)
- React Native Maps
- Redux Toolkit (state management)
- React Query (data fetching)

**Admin Portal:**
- React 18+
- TypeScript
- Material-UI or Tailwind CSS
- React Router
- React Query
- Recharts (analytics visualization)
- AWS Amplify

**Backend API:**
- Python 3.11
- AWS Lambda
- boto3 (AWS SDK)
- psycopg2 (PostgreSQL)
- PyJWT (token verification)
- AWS Cognito (authentication)

**Infrastructure:**
- API Gateway (REST API)
- RDS PostgreSQL (relational data)
- DynamoDB (real-time telemetry)
- Cognito (user management)
- IoT Core (device communication)
- CloudWatch (logging & monitoring)
- Secrets Manager (credentials)

## Components and Interfaces

### 1. Mobile Application

#### Core Screens

**Authentication Flow:**
- Login Screen - Email/password authentication
- Registration Screen - New user signup with email verification
- Forgot Password Screen - Password reset flow

**Main Application:**
- Home Dashboard - Bike status, battery level, quick actions
- Station Map - Interactive map showing nearby stations with availability
- Station Details - Station info, battery availability, navigation
- Swap Flow - Multi-step swap process (initiate → confirm → complete)
- Wallet - Balance display, top-up, transaction history
- History - Past swaps with details
- Profile - User settings and preferences
- Notifications - Push notifications list

#### Key Features

**Station Finder:**
- Real-time location tracking
- Map view with station markers
- List view with distance sorting
- Filter by availability
- Navigation integration

**Battery Swap:**
- QR code scanning for station identification
- Real-time availability check
- Wallet balance verification
- Swap progress tracking
- Completion confirmation

**Wallet Management:**
- Balance display
- M-Pesa integration for top-ups
- Transaction history
- Low balance alerts

#### State Management

```typescript
// Redux store structure
interface AppState {
  auth: {
    user: User | null;
    tokens: AuthTokens | null;
    isAuthenticated: boolean;
  };
  stations: {
    nearby: Station[];
    selected: Station | null;
    loading: boolean;
  };
  swaps: {
    current: Swap | null;
    history: Swap[];
    loading: boolean;
  };
  bike: {
    details: Bike | null;
    telemetry: Telemetry | null;
    loading: boolean;
  };
  wallet: {
    balance: number;
    transactions: Transaction[];
    loading: boolean;
  };
}
```

### 2. Admin Portal

#### Core Pages

**Dashboard:**
- KPI cards (total swaps, revenue, active users, stations)
- Swap trend chart (last 7/30 days)
- Top stations by volume
- Recent activity feed
- System health indicators

**Station Management:**
- Station list with search and filters
- Create/Edit station form
- Station details with battery status
- Station analytics
- Bulk operations

**Fleet Management:**
- Bike list with status indicators
- Register new bike
- Bike details with telemetry
- Battery assignment
- Maintenance tracking

**User Management:**
- User list with search
- User details and activity
- Wallet management
- Subscription management

**Analytics & Reports:**
- Time-series charts (swaps, revenue, users)
- Station performance comparison
- Battery health metrics
- Revenue breakdown
- Export to CSV/PDF

#### Component Architecture

```typescript
// Page component structure
AdminDashboard
├── KPICards
├── SwapTrendChart
├── TopStationsTable
└── RecentActivityFeed

StationManagement
├── StationList
│   ├── SearchBar
│   ├── FilterPanel
│   └── StationTable
└── StationForm
    ├── BasicInfoSection
    ├── LocationSection
    ├── OperatingHoursSection
    └── PricingSection

Analytics
├── DateRangePicker
├── MetricSelector
├── ChartContainer
│   ├── LineChart
│   ├── BarChart
│   └── PieChart
└── ExportButton
```

### 3. Backend API

#### API Structure

```
backend/
├── api/                    # API route handlers
│   ├── auth.py            # Authentication endpoints
│   ├── stations.py        # Station endpoints
│   ├── swaps.py           # Swap endpoints
│   ├── users.py           # User profile endpoints
│   ├── bikes.py           # Bike endpoints
│   └── admin.py           # Admin endpoints
├── functions/             # Lambda function handlers
│   ├── api_handler.py    # Main API handler with routing
│   ├── iot_processor.py  # IoT telemetry processor
│   └── stream_processor.py # DynamoDB stream processor
├── models/               # Data models
│   ├── station.py       # Station & Battery models
│   ├── bike.py          # Bike model
│   ├── user.py          # User model
│   ├── swap.py          # Swap transaction model
│   └── payment.py       # Payment model
├── utils/               # Utility functions
│   ├── db.py           # Database utilities
│   ├── auth.py         # Authentication utilities
│   ├── validators.py   # Input validators
│   ├── notifications.py # Push notifications
│   └── iot.py          # IoT communication
└── tests/              # Unit tests
```

#### API Endpoints

**Public Endpoints:**
```
GET  /health                    - Health check
GET  /stations                  - List all stations
GET  /stations/{id}             - Get station details
GET  /stations/nearby           - Find nearby stations
GET  /stations/{id}/availability - Get battery availability
```

**Authentication Endpoints:**
```
POST /auth/register             - Register new user
POST /auth/login                - User login
POST /auth/confirm              - Confirm email
POST /auth/refresh              - Refresh token
POST /auth/forgot-password      - Initiate password reset
POST /auth/reset-password       - Complete password reset
```

**Rider Endpoints (Authenticated):**
```
GET  /profile                   - Get user profile
PUT  /profile                   - Update profile
GET  /bikes/{id}                - Get bike details
POST /swaps                     - Initiate battery swap
PUT  /swaps/{id}/complete       - Complete swap
GET  /swaps/{id}                - Get swap status
GET  /swaps/history             - Get swap history
GET  /wallet                    - Get wallet balance
POST /wallet/topup              - Top up wallet
GET  /wallet/transactions       - Get transaction history
GET  /notifications             - Get notifications
PUT  /notifications/{id}/read   - Mark notification as read
```

**Admin Endpoints (Admin Role Required):**
```
GET  /admin/dashboard           - Dashboard statistics
GET  /admin/stations            - List stations
POST /admin/stations            - Create station
PUT  /admin/stations/{id}       - Update station
DELETE /admin/stations/{id}     - Delete station
GET  /admin/bikes               - List bikes
POST /admin/bikes               - Register bike
PUT  /admin/bikes/{id}          - Update bike
PUT  /admin/bikes/{id}/assign   - Assign bike to user
GET  /admin/users               - List users
GET  /admin/users/{id}          - Get user details
PUT  /admin/users/{id}/wallet   - Adjust wallet balance
GET  /admin/analytics           - Analytics data
GET  /admin/analytics/stations  - Station analytics
GET  /admin/analytics/revenue   - Revenue reports
GET  /admin/analytics/batteries - Battery health metrics
```

#### Request/Response Flow

```
1. Client Request
   ↓
2. API Gateway (CORS, throttling, WAF)
   ↓
3. Lambda Authorizer (verify JWT token)
   ↓
4. API Handler (route to appropriate handler)
   ↓
5. Business Logic (validate, process)
   ↓
6. Data Layer (PostgreSQL/DynamoDB)
   ↓
7. Response (JSON with status code)
```

#### Authentication Middleware

```python
def api_handler(event, context):
    """Main API handler with authentication"""
    
    # Extract token from Authorization header
    token = extract_token(event)
    
    # Verify token and get user
    if token:
        user = verify_token(token)
        if user:
            event['user'] = user
    
    # Route to appropriate handler
    path = event['path']
    method = event['httpMethod']
    
    # Public endpoints
    if path.startswith('/health') or path.startswith('/stations'):
        return route_public(event, context)
    
    # Require authentication
    if 'user' not in event:
        return unauthorized_response()
    
    # Admin endpoints
    if path.startswith('/admin'):
        if not event['user'].get('is_admin'):
            return forbidden_response()
        return route_admin(event, context)
    
    # User endpoints
    return route_user(event, context)
```

## Data Models

### PostgreSQL Schema

**Users Table:**
```sql
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    wallet_balance DECIMAL(10, 2) DEFAULT 0,
    subscription VARCHAR(50) DEFAULT 'basic',
    total_swaps INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    INDEX idx_email (email)
);
```

**Stations Table:**
```sql
CREATE TABLE stations (
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
    updated_at TIMESTAMP,
    INDEX idx_location (latitude, longitude),
    INDEX idx_status (status)
);
```

**Bikes Table:**
```sql
CREATE TABLE bikes (
    bike_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    battery_id VARCHAR(50),
    model VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    battery_level INTEGER,
    odometer DECIMAL(10, 2),
    last_swap TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_status (status)
);
```

**Swaps Table:**
```sql
CREATE TABLE swaps (
    swap_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    bike_id VARCHAR(50) REFERENCES bikes(bike_id),
    station_id VARCHAR(50) REFERENCES stations(station_id),
    old_battery_id VARCHAR(50),
    new_battery_id VARCHAR(50),
    cost DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'initiated',
    duration_seconds INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_station (station_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
);
```

**Wallet Transactions Table:**
```sql
CREATE TABLE wallet_transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    type VARCHAR(20), -- 'topup', 'swap', 'refund'
    amount DECIMAL(10, 2),
    balance_after DECIMAL(10, 2),
    reference VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_user (user_id),
    INDEX idx_type (type),
    INDEX idx_created (created_at)
);
```

### DynamoDB Tables

**Batteries Table:**
- Partition Key: `station_id`
- Sort Key: `battery_id`
- Attributes:
  - charge_level (Number, 0-100)
  - health (Number, 0-100)
  - status (String: available, in_use, charging, maintenance)
  - cycles (Number)
  - last_charged (String, ISO timestamp)
  - created_at (String, ISO timestamp)
- GSI: `status-index` (status, charge_level)

**bike Telemetry Table:**
- Partition Key: `bike_id`
- Sort Key: `timestamp`
- Attributes:
  - battery_level (Number)
  - location (Map: lat, lng)
  - speed (Number)
  - odometer (Number)
  - temperature (Number)
- TTL: 30 days

**Station Telemetry Table:**
- Partition Key: `station_id`
- Sort Key: `timestamp`
- Attributes:
  - available_batteries (Number)
  - energy_consumption (Number)
  - solar_generation (Number)
  - temperature (Number)
- TTL: 90 days

**Notifications Table:**
- Partition Key: `user_id`
- Sort Key: `notification_id`
- Attributes:
  - type (String: swap_complete, wallet_topup, low_balance, alert)
  - title (String)
  - message (String)
  - read (Boolean)
  - metadata (Map)
  - created_at (String, ISO timestamp)
- TTL: 30 days
- GSI: `unread-index` (user_id, read)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After reviewing all testable properties from the prework analysis, several redundancies and consolidation opportunities were identified:

**Redundancies Eliminated:**
- Properties 3.7 and 3.3 both test insufficient wallet balance - consolidated into Property 3
- Properties 7.5 and 7.1 both test bike ownership authorization - consolidated into Property 7
- Properties 5.5 (empty history) is an edge case handled by Property 5
- Property 2.5 (no nearby stations) is an edge case handled by Property 2
- Property 8.5 (data source usage) is an implementation detail, not a testable property

**Properties Consolidated:**
- Swap initiation validations (3.1-3.6) consolidated into comprehensive swap initiation property
- Swap completion updates (4.2-4.5) consolidated into swap completion state transitions property
- Notification sending (12.1, 12.2) consolidated into notification delivery property
- Battery swap flow properties combined to reduce redundancy

This reflection ensures each property provides unique validation value without logical redundancy.

### Correctness Properties

Property 1: User registration creates valid account
*For any* valid user registration data (email, password, name, phone), the system should create a Cognito account and send a verification email
**Validates: Requirements 1.1, 1.2**

Property 2: Authentication tokens have correct expiration
*For any* valid login credentials, the returned authentication token should have an expiration time of exactly 24 hours from issuance
**Validates: Requirements 1.3**

Property 3: Expired tokens are rejected
*For any* expired authentication token, API requests should be rejected with 401 status
**Validates: Requirements 1.4**

Property 4: Password validation enforces requirements
*For any* password string, it should be accepted if and only if it contains at least 8 characters with uppercase, lowercase, and numbers
**Validates: Requirements 1.5**

Property 5: Nearby stations are within radius and sorted
*For any* location coordinates and radius, all returned stations should be within the specified radius and sorted by distance ascending
**Validates: Requirements 2.1**

Property 6: Station responses contain required fields
*For any* station query response, each station should include name, address, distance, available_batteries, and operating_hours fields
**Validates: Requirements 2.2**

Property 7: Haversine distance calculation is accurate
*For any* two coordinate pairs, the calculated distance should match the Haversine formula result within 0.1km tolerance
**Validates: Requirements 2.3**

Property 8: Station availability reflects DynamoDB state
*For any* station, when battery availability is updated in DynamoDB, the API should return the updated count within 2 seconds
**Validates: Requirements 2.4**

Property 9: Swap initiation validates all preconditions
*For any* swap request, it should succeed if and only if: (1) bike belongs to rider, (2) station has available battery, (3) wallet balance >= swap cost
**Validates: Requirements 3.1, 3.2, 3.3, 3.7**

Property 10: Swap initiation creates transaction and updates wallet
*For any* successful swap initiation, the system should create a swap transaction with status "initiated", deduct cost from wallet, and reserve a battery
**Validates: Requirements 3.4, 3.5, 3.6**

Property 11: Swap completion requires initiated status
*For any* swap completion request, it should succeed if and only if the swap status is "initiated"
**Validates: Requirements 4.1**

Property 12: Swap completion updates all related entities
*For any* completed swap, the system should update: (1) bike battery_id, (2) swap status to "completed", (3) old battery to "charging", (4) new battery to "in-use"
**Validates: Requirements 4.2, 4.3, 4.4, 4.5**

Property 13: Swap completion triggers notification
*For any* completed swap, a push notification should be sent to the rider with swap details
**Validates: Requirements 4.6**

Property 14: Swap history returns all user swaps sorted
*For any* rider, their swap history should include all their swaps sorted by timestamp descending
**Validates: Requirements 5.1**

Property 15: Swap history entries contain required fields
*For any* swap in history, it should include swap_id, station_name, timestamp, cost, and status
**Validates: Requirements 5.2**

Property 16: Pagination returns correct page with metadata
*For any* page request with page number and size, the response should contain exactly that page of results plus total count and page metadata
**Validates: Requirements 5.3, 5.4**

Property 17: Wallet top-up validates amount bounds
*For any* top-up amount, it should be accepted if and only if it is between 10 and 1000 GHS inclusive
**Validates: Requirements 6.1, 6.6**

Property 18: Successful payment increases wallet balance
*For any* successful payment of amount X, the wallet balance should increase by exactly X
**Validates: Requirements 6.3**

Property 19: Successful payment creates transaction record
*For any* successful payment, a wallet transaction record with type "topup" should be created
**Validates: Requirements 6.4**

Property 20: Failed payment preserves wallet balance
*For any* failed payment, the wallet balance should remain unchanged
**Validates: Requirements 6.5**

Property 21: Bike details require ownership
*For any* bike details request, it should succeed if and only if the bike belongs to the requesting rider
**Validates: Requirements 7.1, 7.5**

Property 22: Bike details include all required fields
*For any* bike details response, it should include bike_id, model, battery_level, battery_id, location, odometer, and last_swap
**Validates: Requirements 7.2**

Property 23: Bike details include telemetry freshness indicator
*For any* bike with telemetry older than 5 minutes, the response should include a staleness indicator
**Validates: Requirements 7.4**

Property 24: Admin endpoints require admin role
*For any* admin endpoint request, it should succeed if and only if the user has admin role
**Validates: Requirements 8.1, 9.6**

Property 25: Dashboard includes all required metrics
*For any* dashboard request, the response should include total_swaps_today, total_revenue_today, active_riders, total_stations, swap_trend_7days, and top_5_stations
**Validates: Requirements 8.2, 8.3, 8.4**

Property 26: Station creation validates required fields
*For any* station creation request, it should succeed if and only if all required fields (name, latitude, longitude, address, city, capacity, pricing) are present and valid
**Validates: Requirements 9.1, 9.2**

Property 27: Station creation generates unique ID
*For any* two station creation requests, they should receive different station IDs
**Validates: Requirements 9.3**

Property 28: Station update modifies only specified fields
*For any* station update with fields F, only fields in F should change, and updated_at should be set to current time
**Validates: Requirements 9.4**

Property 29: Station deletion is soft delete
*For any* station deletion, the station record should remain in the database with status changed to "inactive"
**Validates: Requirements 9.5**

Property 30: Bike registration sets correct initial state
*For any* new bike registration, the bike should have status "active" and battery_level 100
**Validates: Requirements 10.2**

Property 31: Bike assignment updates user ID
*For any* bike assignment to user U, the bike's user_id field should be set to U
**Validates: Requirements 10.3**

Property 32: Analytics aggregates data correctly
*For any* date range, analytics should return accurate aggregations of swap volume, revenue, and duration by day
**Validates: Requirements 11.1**

Property 33: Station analytics groups by station
*For any* date range, station analytics should return swap count and revenue per station for that period
**Validates: Requirements 11.2**

Property 34: Low balance triggers notification
*For any* wallet balance update that results in balance < 10 GHS, a low balance notification should be sent
**Validates: Requirements 12.3**

Property 35: Notifications are stored with TTL
*For any* notification created, it should be stored in DynamoDB with TTL set to 30 days from creation
**Validates: Requirements 12.4**

Property 36: Notification query returns unread sorted
*For any* notification query, it should return only unread notifications sorted by timestamp descending
**Validates: Requirements 12.5**

Property 37: Telemetry processing is timely
*For any* telemetry message published to IoT Core, it should be processed and stored within 2 seconds
**Validates: Requirements 13.1**

Property 38: Bike telemetry updates DynamoDB
*For any* bike telemetry message, the bike's battery_level and location should be updated in DynamoDB
**Validates: Requirements 13.2**

Property 39: Low battery triggers alert
*For any* telemetry indicating battery_level < 10%, an alert notification should be sent to the rider
**Validates: Requirements 13.5**

Property 40: Error responses include correct status codes
*For any* error condition, the response should have status 400 for invalid input, 401 for auth failure, 403 for authorization failure, or 500 for server error
**Validates: Requirements 14.3**

Property 41: Database failures trigger retry with backoff
*For any* database query failure, the system should retry up to 3 times with exponential backoff before returning error
**Validates: Requirements 14.4**

Property 42: All logs include correlation ID
*For any* log entry, it should include a request correlation ID for tracing
**Validates: Requirements 14.5**

Property 43: Phone number validation enforces Ghanaian format
*For any* phone number update, it should be accepted if and only if it matches the format +233XXXXXXXXX
**Validates: Requirements 15.2**

Property 44: Profile updates preserve immutable fields
*For any* profile update request, email and user_id fields should remain unchanged regardless of request content
**Validates: Requirements 15.5**

## Error Handling

### Error Response Format

All API errors follow a consistent JSON structure:

```json
{
  "error": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": {
    "field": "Additional context"
  },
  "request_id": "correlation-id-for-tracing"
}
```

### HTTP Status Codes

- **200 OK** - Successful request
- **201 Created** - Resource created successfully
- **400 Bad Request** - Invalid input or validation failure
- **401 Unauthorized** - Missing or invalid authentication token
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - Resource not found
- **409 Conflict** - Resource conflict (e.g., duplicate email)
- **429 Too Many Requests** - Rate limit exceeded
- **500 Internal Server Error** - Server-side error
- **503 Service Unavailable** - Temporary service disruption

### Error Categories

**Validation Errors (400):**
- Missing required fields
- Invalid data format
- Out of range values
- Invalid coordinates
- Password requirements not met

**Authentication Errors (401):**
- Missing Authorization header
- Invalid or expired token
- Token verification failure

**Authorization Errors (403):**
- Insufficient permissions (non-admin accessing admin endpoints)
- Resource ownership violation (accessing another user's bike)

**Resource Errors (404):**
- Station not found
- Bike not found
- Swap not found
- User not found

**Business Logic Errors (400):**
- Insufficient wallet balance
- No available batteries at station
- Swap already completed
- Invalid swap status transition

**External Service Errors (500/503):**
- Database connection failure
- DynamoDB timeout
- IoT Core communication failure
- M-Pesa API failure
- Cognito service error

### Retry Strategy

**Automatic Retries:**
- Database queries: 3 retries with exponential backoff (100ms, 200ms, 400ms)
- DynamoDB operations: 3 retries with exponential backoff
- IoT Core publishes: 2 retries with 500ms delay

**No Retries:**
- Validation errors (400)
- Authentication/Authorization errors (401/403)
- Resource not found (404)
- Business logic errors (400)

### Logging Strategy

**Log Levels:**
- **ERROR** - All exceptions and failures
- **WARN** - Retry attempts, deprecated API usage
- **INFO** - Request/response, business events (swap initiated, payment processed)
- **DEBUG** - Detailed execution flow (development only)

**Log Structure:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "ERROR",
  "request_id": "abc-123-def",
  "user_id": "USER123",
  "endpoint": "/swaps",
  "method": "POST",
  "status_code": 500,
  "error": "Database connection failed",
  "stack_trace": "...",
  "duration_ms": 1250
}
```

## Testing Strategy

### Unit Testing

**Framework:** pytest for Python backend

**Coverage Requirements:**
- Minimum 80% code coverage
- 100% coverage for critical paths (authentication, payment, swap logic)

**Unit Test Categories:**

1. **Model Tests** - Data model validation and business logic
   - Station distance calculations
   - Battery availability checks
   - User wallet operations
   - Swap status transitions

2. **API Handler Tests** - Endpoint logic without external dependencies
   - Request validation
   - Response formatting
   - Error handling
   - Authorization checks

3. **Utility Tests** - Helper functions
   - Haversine distance formula
   - Phone number validation
   - Coordinate validation
   - Token verification (mocked)

4. **Database Tests** - Query logic with test database
   - CRUD operations
   - Transaction handling
   - Query result formatting

### Property-Based Testing

**Framework:** Hypothesis for Python

**Configuration:**
- Minimum 100 iterations per property test
- Deterministic seed for reproducibility
- Shrinking enabled for minimal failing examples

**Property Test Categories:**

1. **Input Validation Properties**
   - Password requirements (Property 4)
   - Coordinate validation (Property 7)
   - Amount bounds (Property 17)
   - Phone format (Property 43)

2. **Business Logic Properties**
   - Swap preconditions (Property 9)
   - Wallet balance updates (Property 18, 20)
   - State transitions (Property 12)
   - Pagination correctness (Property 16)

3. **Data Integrity Properties**
   - Unique ID generation (Property 27)
   - Immutable fields (Property 44)
   - Required fields presence (Property 6, 15, 22)

4. **Authorization Properties**
   - Ownership checks (Property 21)
   - Admin role requirements (Property 24)

**Property Test Tagging:**
Each property-based test MUST include a comment with this format:
```python
# Feature: ecovolt-application, Property 9: Swap initiation validates all preconditions
@given(swap_request=swap_requests(), user=users(), station=stations())
def test_swap_preconditions(swap_request, user, station):
    ...
```

### Integration Testing

**Test Scenarios:**

1. **End-to-End Swap Flow**
   - User finds nearby station
   - Initiates swap
   - Completes swap
   - Verifies all state updates

2. **Wallet Top-Up Flow**
   - User initiates top-up
   - M-Pesa payment processes
   - Wallet balance updates
   - Transaction record created

3. **Admin Station Management**
   - Create station
   - Update station details
   - View station analytics
   - Soft delete station

4. **IoT Telemetry Processing**
   - Bike publishes telemetry
   - Lambda processes message
   - DynamoDB updated
   - Low battery alert triggered

### Mobile App Testing

**Unit Tests:**
- Redux reducers and actions
- Utility functions
- Component logic

**Component Tests:**
- React Native Testing Library
- Component rendering
- User interactions
- Navigation flows

**E2E Tests:**
- Detox framework
- Critical user journeys
- Authentication flow
- Swap flow
- Wallet top-up

### Admin Portal Testing

**Unit Tests:**
- React components
- Custom hooks
- Utility functions

**Integration Tests:**
- React Testing Library
- API integration
- Form submissions
- Data fetching

**E2E Tests:**
- Cypress or Playwright
- Dashboard loading
- Station CRUD operations
- Analytics viewing

### Performance Testing

**Load Testing:**
- Apache JMeter or Locust
- Target: 1000 concurrent users
- Key endpoints: /stations/nearby, /swaps, /wallet/topup
- Success criteria: 95th percentile < 500ms

**Stress Testing:**
- Gradual load increase to find breaking point
- Monitor Lambda throttling
- Monitor database connection pool

### Security Testing

**Authentication Tests:**
- Token expiration handling
- Invalid token rejection
- Token refresh flow

**Authorization Tests:**
- Role-based access control
- Resource ownership validation
- Admin endpoint protection

**Input Validation Tests:**
- SQL injection attempts
- XSS attempts
- Invalid data formats
- Boundary value testing

## Deployment Strategy

### Backend Deployment

**Lambda Packaging:**
```bash
# Install dependencies
pip install -r requirements.txt -t package/

# Copy source code
cp -r api functions models utils package/

# Create deployment package
cd package && zip -r ../lambda.zip . && cd ..

# Upload to S3
aws s3 cp lambda.zip s3://ecovolt-deployments/backend/lambda.zip
```

**Terraform Deployment:**
```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan

# Apply changes
terraform apply prod.tfplan
```

**Database Migrations:**
```bash
# Run migrations
psql -h $DB_ENDPOINT -U $DB_USER -d ecovolt -f migrations/001_initial_schema.sql
psql -h $DB_ENDPOINT -U $DB_USER -d ecovolt -f migrations/002_add_indexes.sql
```

### Mobile App Deployment

**iOS:**
```bash
cd application/mobile

# Install dependencies
npm install

# Build for iOS
npx react-native run-ios --configuration Release

# Archive and upload to App Store Connect
xcodebuild archive -workspace ios/EcoVolt.xcworkspace -scheme EcoVolt
```

**Android:**
```bash
# Build APK
cd android && ./gradlew assembleRelease

# Build AAB for Play Store
./gradlew bundleRelease

# Upload to Google Play Console
```

### Admin Portal Deployment

```bash
cd application/admin-portal

# Install dependencies
npm install

# Build for production
npm run build

# Deploy to S3
aws s3 sync build/ s3://ecovolt-admin-portal/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### Environment Configuration

**Development:**
- API: dev-api.ecovolt.thekloudwiz.com
- Database: ecovolt-dev RDS instance
- Cognito: ecovolt-dev user pool
- IoT: ecovolt/dev/* topics

**Staging:**
- API: staging-api.ecovolt.thekloudwiz.com
- Database: ecovolt-staging RDS instance
- Cognito: ecovolt-staging user pool
- IoT: ecovolt/staging/* topics

**Production:**
- API: api.ecovolt.thekloudwiz.com
- Database: ecovolt-prod RDS instance (Multi-AZ)
- Cognito: ecovolt-prod user pool
- IoT: ecovolt/prod/* topics

## Monitoring and Observability

### CloudWatch Metrics

**Lambda Metrics:**
- Invocations
- Errors
- Duration (p50, p95, p99)
- Throttles
- Concurrent executions

**API Gateway Metrics:**
- Request count
- 4xx errors
- 5xx errors
- Latency
- Cache hit/miss

**Database Metrics:**
- CPU utilization
- Connection count
- Read/Write IOPS
- Storage usage
- Replication lag

**DynamoDB Metrics:**
- Read/Write capacity units
- Throttled requests
- Latency
- Item count

### CloudWatch Alarms

**Critical Alarms (PagerDuty):**
- Lambda error rate > 5%
- API Gateway 5xx rate > 1%
- Database CPU > 80%
- Database connection count > 90% of max

**Warning Alarms (Email):**
- Lambda duration p95 > 3000ms
- API Gateway 4xx rate > 10%
- Database storage > 80%
- DynamoDB throttled requests > 0

### Logging

**Log Groups:**
- `/aws/lambda/ecovolt-{env}-api-handler`
- `/aws/lambda/ecovolt-{env}-iot-processor`
- `/aws/lambda/ecovolt-{env}-stream-processor`
- `/aws/apigateway/ecovolt-{env}`

**Log Retention:**
- Development: 7 days
- Staging: 30 days
- Production: 90 days

### Distributed Tracing

**AWS X-Ray:**
- Enabled for all Lambda functions
- Trace API Gateway requests
- Track database queries
- Monitor external service calls

**Trace Analysis:**
- Identify slow endpoints
- Find bottlenecks
- Analyze error patterns
- Monitor service dependencies

### Dashboards

**Operations Dashboard:**
- Request rate and latency
- Error rates by endpoint
- Active users
- Swap completion rate

**Business Dashboard:**
- Daily swaps
- Revenue
- New user registrations
- Station utilization

**Infrastructure Dashboard:**
- Lambda metrics
- Database metrics
- DynamoDB metrics
- Cost tracking

## Security Considerations

### Authentication & Authorization

- JWT tokens with 24-hour expiration
- Refresh tokens for extended sessions
- Role-based access control (Rider, Admin)
- Multi-factor authentication for admin users

### Data Protection

- TLS 1.2+ for all API communication
- Database encryption at rest (AES-256)
- Secrets Manager for credentials
- KMS for encryption key management

### API Security

- WAF rules for common attacks
- Rate limiting per user (100 req/min)
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- CORS configuration

### Compliance

- GDPR compliance for user data
- Data retention policies
- Right to deletion
- Audit logging
- Regular security assessments

## Performance Optimization

### Caching Strategy

**API Gateway Caching:**
- Cache /stations endpoint (5 minutes)
- Cache /stations/nearby (1 minute)
- No caching for authenticated endpoints

**Application Caching:**
- Redis/ElastiCache for session data
- Cache user profiles (5 minutes)
- Cache station data (1 minute)

### Database Optimization

**Indexes:**
- stations(latitude, longitude) for nearby search
- swaps(user_id, created_at) for history
- bikes(user_id) for user bikes
- wallet_transactions(user_id, created_at)

**Query Optimization:**
- Use EXPLAIN ANALYZE for slow queries
- Implement connection pooling
- Use read replicas for analytics

### Lambda Optimization

- Provisioned concurrency for critical functions
- Optimize cold start time (< 1s)
- Reuse database connections
- Minimize deployment package size

## Future Enhancements

1. **Real-time Features**
   - WebSocket support for live updates
   - Real-time station availability
   - Live swap progress tracking

2. **Advanced Analytics**
   - Predictive battery demand
   - Route optimization
   - Maintenance scheduling

3. **Payment Options**
   - Credit/debit card support
   - Subscription plans
   - Corporate accounts

4. **Mobile Features**
   - Offline mode
   - Route planning
   - Social features (share rides)

5. **Admin Features**
   - Advanced reporting
   - Automated alerts
   - Inventory management
   - Staff management

---

**Design document complete and ready for implementation planning!**
