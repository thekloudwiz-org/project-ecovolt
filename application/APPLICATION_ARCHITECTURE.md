# EcoVolt Application Architecture

## Overview

The EcoVolt application consists of three main components:
1. **Backend API** - Python Lambda functions
2. **Mobile App** - React Native for riders
3. **Admin Portal** - React web application

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     EcoVolt Application Stack                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │ Mobile App   │         │ Admin Portal │                     │
│  │ (React Native│         │ (React)      │                     │
│  └──────┬───────┘         └──────┬───────┘                     │
│         │                        │                              │
│         └────────────┬───────────┘                              │
│                      │                                          │
│              ┌───────▼────────┐                                 │
│              │  API Gateway   │                                 │
│              │  + Cognito     │                                 │
│              └───────┬────────┘                                 │
│                      │                                          │
│         ┌────────────┼────────────┐                             │
│         │            │            │                             │
│    ┌────▼────┐  ┌───▼────┐  ┌───▼────┐                        │
│    │ Lambda  │  │ Lambda │  │ Lambda │                        │
│    │ (API)   │  │ (IoT)  │  │(Stream)│                        │
│    └────┬────┘  └───┬────┘  └───┬────┘                        │
│         │           │           │                              │
│    ┌────▼───────────▼───────────▼────┐                         │
│    │  RDS PostgreSQL + DynamoDB      │                         │
│    └─────────────────────────────────┘                         │
│                                                                  │
│    ┌─────────────────────────────────┐                         │
│    │  IoT Core (Bikes & Stations)    │                         │
│    └─────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## 📱 Mobile App (React Native)

### Features
- **User Authentication** - Login/Register with Cognito
- **Station Finder** - Find nearby swap stations with map
- **Battery Swap** - Initiate and track battery swaps
- **Wallet** - Manage balance and payments
- **Ride History** - View past swaps and rides
- **Bike Status** - Real-time battery level and bike health
- **Notifications** - Push notifications for swap completion

### Tech Stack
- React Native 0.72+
- React Navigation
- AWS Amplify (Auth, API)
- React Native Maps
- Redux Toolkit (State management)
- TypeScript

### Key Screens
1. **Login/Register** - Authentication
2. **Home** - Dashboard with bike status
3. **Map** - Find nearby stations
4. **Station Details** - View station info and availability
5. **Swap** - Initiate swap process
6. **Wallet** - Manage payments
7. **Profile** - User settings

## 💻 Admin Portal (React Web)

### Features
- **Dashboard** - Overview analytics
- **Station Management** - CRUD operations for stations
- **Bike Management** - Monitor and manage bikes
- **User Management** - View and manage users
- **Analytics** - Usage statistics and reports
- **Battery Monitoring** - Track battery health and cycles
- **Revenue Tracking** - Financial reports

### Tech Stack
- React 18+
- TypeScript
- Material-UI / Tailwind CSS
- React Query (Data fetching)
- Recharts (Analytics)
- AWS Amplify

### Key Pages
1. **Dashboard** - KPIs and charts
2. **Stations** - Station list and management
3. **Bikes** - Bike fleet management
4. **Users** - User management
5. **Analytics** - Detailed reports
6. **Settings** - System configuration

## 🔧 Backend API (Python Lambda)

### Core Modules

#### 1. API Handlers (`api/`)
- `stations.py` - Station endpoints
- `swaps.py` - Swap transaction endpoints
- `users.py` - User profile endpoints
- `admin.py` - Admin endpoints
- `bikes.py` - Bike management endpoints

#### 2. Data Models (`models/`)
- `station.py` - Station and Battery models
- `bike.py` - Bike model
- `user.py` - User model
- `swap.py` - Swap transaction model
- `payment.py` - Payment model

#### 3. Utilities (`utils/`)
- `db.py` - Database connection and queries
- `auth.py` - JWT verification and authorization
- `validators.py` - Input validation
- `notifications.py` - Push notifications
- `iot.py` - IoT device communication

### API Endpoints

#### Public Endpoints
```
GET  /health                    - Health check
GET  /stations                  - List all stations
GET  /stations/{id}             - Get station details
GET  /stations/nearby?lat=&lng= - Find nearby stations
```

#### Authenticated Endpoints (Riders)
```
POST /auth/register             - Register new user
POST /auth/login                - User login
GET  /profile                   - Get user profile
PUT  /profile                   - Update profile
GET  /bikes/{id}                - Get bike details
POST /swaps                     - Initiate battery swap
GET  /swaps/{id}                - Get swap status
GET  /swaps/history             - Get swap history
GET  /wallet                    - Get wallet balance
POST /wallet/topup              - Top up wallet
GET  /notifications             - Get notifications
```

#### Admin Endpoints
```
GET  /admin/dashboard           - Dashboard stats
GET  /admin/stations            - List stations
POST /admin/stations            - Create station
PUT  /admin/stations/{id}       - Update station
DELETE /admin/stations/{id}     - Delete station
GET  /admin/bikes               - List bikes
POST /admin/bikes               - Register bike
PUT  /admin/bikes/{id}          - Update bike
GET  /admin/users               - List users
GET  /admin/analytics           - Analytics data
GET  /admin/revenue             - Revenue reports
```

## 📊 Data Models

### Station
```python
{
  "station_id": "STN001",
  "name": "Accra Central Station",
  "location": {"lat": 5.603717, "lng": -0.186964},
  "address": "Independence Avenue, Accra",
  "city": "Accra",
  "status": "active",
  "available_batteries": 15,
  "total_capacity": 20,
  "operating_hours": {"open": "06:00", "close": "22:00"},
  "amenities": ["parking", "waiting_area", "wifi"],
  "pricing": {"swap_fee": 5.0, "currency": "GHS"}
}
```

### Bike
```python
{
  "bike_id": "BIKE001",
  "user_id": "USER123",
  "battery_id": "BAT456",
  "model": "EcoVolt E-Bike Pro",
  "status": "active",
  "battery_level": 85,
  "location": {"lat": -1.286389, "lng": 36.817223},
  "odometer": 1250.5,
  "last_swap": "2024-01-15T10:30:00Z"
}
```

### Swap Transaction
```python
{
  "swap_id": "SWP789",
  "user_id": "USER123",
  "bike_id": "BIKE001",
  "station_id": "STN001",
  "old_battery_id": "BAT456",
  "new_battery_id": "BAT789",
  "timestamp": "2024-01-15T10:30:00Z",
  "duration_seconds": 45,
  "cost": 50.0,
  "status": "completed"
}
```

### User
```python
{
  "user_id": "USER123",
  "email": "rider@example.com",
  "name": "Kwame Mensah",
  "phone": "+233201234567",
  "wallet_balance": 50.0,
  "subscription": "basic",
  "created_at": "2024-01-01T00:00:00Z",
  "total_swaps": 45
}
```

## 🔐 Authentication Flow

1. **User Registration**
   - User signs up via mobile app
   - Cognito creates user account
   - User verifies email/phone
   - Profile created in RDS

2. **User Login**
   - User enters credentials
   - Cognito validates and returns JWT tokens
   - App stores tokens securely
   - Tokens used for API authentication

3. **API Authorization**
   - Client sends JWT in Authorization header
   - Lambda verifies token with Cognito
   - User context added to request
   - Admin routes check user role

## 🔄 Battery Swap Flow

1. **Find Station**
   - User opens app and views nearby stations
   - App shows available batteries at each station
   - User selects station and navigates

2. **Initiate Swap**
   - User arrives at station
   - Scans QR code or enters station ID
   - App requests swap via API
   - System reserves a charged battery

3. **Physical Swap**
   - User removes depleted battery
   - Places it in charging slot
   - Takes charged battery
   - Installs in bike

4. **Complete Swap**
   - IoT device confirms new battery installed
   - System updates records
   - Payment deducted from wallet
   - User receives confirmation

## 📡 IoT Integration

### Device Communication
- **Bikes** - Send telemetry (battery level, location, speed)
- **Stations** - Report battery status and availability
- **Real-time Updates** - Via AWS IoT Core MQTT

### IoT Topics
```
ecovolt/bikes/{bike_id}/telemetry    - Bike data
ecovolt/bikes/{bike_id}/commands     - Commands to bike
ecovolt/stations/{station_id}/status - Station status
ecovolt/stations/{station_id}/batteries - Battery updates
```

## 🚀 Deployment

### Backend
```bash
# Deploy infrastructure
terraform apply -var-file="environments/prod.tfvars"

# Package and deploy Lambda functions
cd application/backend
./deploy.sh prod
```

### Mobile App
```bash
cd application/mobile
npm install
npx react-native run-android  # or run-ios
```

### Admin Portal
```bash
cd application/admin-portal
npm install
npm run build
aws s3 sync build/ s3://ecovolt-admin-portal/
```

## 📈 Next Steps

1. **Complete Backend Implementation**
   - Implement all API endpoints
   - Add comprehensive error handling
   - Write unit and integration tests

2. **Build Mobile App**
   - Set up React Native project
   - Implement core screens
   - Integrate with backend API

3. **Build Admin Portal**
   - Set up React project
   - Create dashboard and management screens
   - Implement analytics

4. **Testing**
   - Unit tests for all components
   - Integration tests for API
   - E2E tests for critical flows

5. **Production Deployment**
   - Set up CI/CD pipeline
   - Configure monitoring and alerts
   - Deploy to production environment

## 📝 Development Guidelines

- Follow Python PEP 8 style guide
- Use TypeScript for type safety
- Write tests for all new features
- Document API changes
- Use semantic versioning
- Keep dependencies updated

---

**Ready to build sustainable transportation in Ghana!** 🇬🇭⚡
