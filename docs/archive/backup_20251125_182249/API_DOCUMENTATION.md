# EcoVolt API Documentation

## Overview

The EcoVolt API is a RESTful API service that powers the EcoVolt battery swapping platform. It provides endpoints for user authentication, station management, battery swaps, wallet operations, and administrative functions.

**Base URL**: `https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1`

**Authentication**: JWT tokens via AWS Cognito

## Authentication

### Register User
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

### Login
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

### Confirm Email
```http
POST /auth/confirm
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}
```

## Stations

### Get Nearby Stations
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

### Get Station Details
```http
GET /stations/{station_id}
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "station": {
    "id": "station-001",
    "name": "Accra Central Station",
    "address": "123 Independence Ave",
    "city": "Accra",
    "latitude": 5.6037,
    "longitude": -0.187,
    "capacity": 20,
    "availableBatteries": 8,
    "swapCost": 15.00,
    "operatingHours": "24/7",
    "status": "active"
  },
  "realtimeBatteryCount": 8,
  "recentSwaps": 45
}
```

## Swaps

### Initiate Swap
```http
POST /swaps
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "bike_id": "BIKE001",
  "station_id": "station-001"
}
```

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

### Complete Swap
```http
PUT /swaps/{swap_id}/complete
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "swap": {
    "id": "swap-001",
    "status": "completed",
    "completedAt": "2024-01-15T10:35:00Z",
    "duration": 5
  },
  "message": "Swap completed successfully"
}
```

### Get Swap History
```http
GET /swaps/history?page=1&page_size=20
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "swaps": [
    {
      "id": "swap-001",
      "stationName": "Accra Central Station",
      "cost": 15.00,
      "status": "completed",
      "initiatedAt": "2024-01-15T10:30:00Z",
      "completedAt": "2024-01-15T10:35:00Z",
      "duration": 5
    }
  ],
  "total": 50,
  "page": 1,
  "pageSize": 20,
  "totalPages": 3
}
```

## Wallet

### Get Wallet Balance
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

### Initiate Top-Up
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

**Response**:
```json
{
  "transaction": {
    "id": "txn-001",
    "amount": 100.00,
    "status": "pending",
    "paymentMethod": "mtn_momo"
  },
  "message": "Top-up initiated. Please approve on your phone."
}
```

### Get Transaction History
```http
GET /wallet/transactions?page=1&page_size=20
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "transactions": [
    {
      "id": "txn-001",
      "type": "topup",
      "amount": 100.00,
      "balanceBefore": 50.50,
      "balanceAfter": 150.50,
      "status": "completed",
      "createdAt": "2024-01-15T09:00:00Z"
    }
  ],
  "total": 25,
  "page": 1,
  "pageSize": 20
}
```

## Bikes

### Get Bike Details
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

## Profile

### Get User Profile
```http
GET /profile
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "user": {
    "id": "user-001",
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+233XXXXXXXXX",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

### Update Profile
```http
PUT /profile
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "John Updated",
  "phone": "+233YYYYYYYYY"
}
```

## Notifications

### Get Notifications
```http
GET /notifications
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "notifications": [
    {
      "id": "notif-001",
      "type": "swap_complete",
      "title": "Swap Completed",
      "message": "Your battery swap at Accra Central Station is complete",
      "read": false,
      "createdAt": "2024-01-15T10:35:00Z"
    }
  ],
  "unreadCount": 3
}
```

### Mark as Read
```http
PUT /notifications/{notification_id}/read
Authorization: Bearer {access_token}
```

## Admin Endpoints

All admin endpoints require the user to be in the `admin` Cognito group.

### Dashboard Metrics
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

### List Stations (Admin)
```http
GET /admin/stations?page=1&page_size=20
Authorization: Bearer {admin_access_token}
```

### Create Station
```http
POST /admin/stations
Authorization: Bearer {admin_access_token}
Content-Type: application/json

{
  "name": "New Station",
  "address": "456 Main St",
  "city": "Kumasi",
  "latitude": 6.6885,
  "longitude": -1.6244,
  "capacity": 15,
  "swapCost": 15.00,
  "operatingHours": "6:00 AM - 10:00 PM"
}
```

### Update Station
```http
PUT /admin/stations/{station_id}
Authorization: Bearer {admin_access_token}
Content-Type: application/json

{
  "capacity": 20,
  "status": "active"
}
```

### Delete Station
```http
DELETE /admin/stations/{station_id}
Authorization: Bearer {admin_access_token}
```

### List Bikes (Admin)
```http
GET /admin/bikes?page=1&page_size=20
Authorization: Bearer {admin_access_token}
```

### Register Bike
```http
POST /admin/bikes
Authorization: Bearer {admin_access_token}
Content-Type: application/json

{
  "bike_id": "BIKE002",
  "model": "EcoVolt E-Moto 2024",
  "battery_id": "BAT-002"
}
```

### Assign Bike to User
```http
PUT /admin/bikes/{bike_id}/assign
Authorization: Bearer {admin_access_token}
Content-Type: application/json

{
  "user_id": "user-001"
}
```

### List Users (Admin)
```http
GET /admin/users?page=1&page_size=20
Authorization: Bearer {admin_access_token}
```

### Adjust Wallet Balance
```http
PUT /admin/users/{user_id}/wallet
Authorization: Bearer {admin_access_token}
Content-Type: application/json

{
  "amount": 50.00,
  "reason": "Promotional credit"
}
```

### Get Analytics
```http
GET /admin/analytics?start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer {admin_access_token}
```

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid input parameters |
| 401 | Unauthorized - Invalid or missing authentication token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource does not exist |
| 409 | Conflict - Resource already exists or state conflict |
| 500 | Internal Server Error - Server-side error |

## Error Response Format

```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Invalid latitude value",
    "correlationId": "req-12345"
  }
}
```

## Rate Limiting

- **User endpoints**: 100 requests per minute
- **Admin endpoints**: 200 requests per minute

## Pagination

All list endpoints support pagination with the following parameters:
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20, max: 100)

Response includes:
```json
{
  "data": [...],
  "total": 150,
  "page": 1,
  "pageSize": 20,
  "totalPages": 8
}
```

## Postman Collection

A Postman collection with all endpoints is available at:
`docs/EcoVolt_API.postman_collection.json`

## Support

For API support, contact: api-support@ecovolt.com
