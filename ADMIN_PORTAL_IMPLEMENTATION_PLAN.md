# Admin Portal Implementation Plan

## Current Status
- ✅ Backend APIs are fully implemented and deployed
- ✅ Admin portal foundation is set up (auth, routing, layout)
- ✅ API service layer is configured
- ❌ Bikes, Users, and Analytics pages have placeholder content
- ❌ Types don't match backend API responses exactly

## Backend API Endpoints Available

### Dashboard
- `GET /admin/dashboard` - Returns metrics, swap_trend_7days, top_stations

### Stations
- `GET /admin/stations` - List with pagination
- `POST /admin/stations` - Create station
- `PUT /admin/stations/{id}` - Update station
- `DELETE /admin/stations/{id}` - Soft delete

### Bikes
- `GET /admin/bikes` - List with pagination, includes telemetry
- `POST /admin/bikes` - Register new bike
- `PUT /admin/bikes/{id}` - Update bike
- `PUT /admin/bikes/{id}/assign` - Assign to user

### Users
- `GET /admin/users` - List with pagination
- `GET /admin/users/{id}` - Get details with stats and bikes
- `PUT /admin/users/{id}/wallet` - Adjust wallet balance

### Analytics
- `GET /admin/analytics` - Time-series data (swaps, revenue, users)
- `GET /admin/analytics/stations` - Per-station analytics
- `GET /admin/analytics/revenue` - Revenue breakdown
- `GET /admin/analytics/batteries` - Battery health metrics

## Implementation Tasks

### 1. Update Types (types/index.ts)
- Fix DashboardMetrics to match backend response
- Fix Station type to match backend
- Fix Bike type to match backend
- Fix User type to match backend
- Add Analytics types for all endpoints
- Add proper pagination types

### 2. Update API Service (services/api.ts)
- Fix getDashboardMetrics response mapping
- Fix getUsers response mapping
- Add getBatteryAnalytics function
- Update type imports

### 3. Implement BikesPage (pages/BikesPage.tsx)
- Create bike list table with pagination
- Add filters (status, assigned/unassigned)
- Add bike registration form/modal
- Add bike details view with telemetry
- Add bike assignment functionality
- Add bike update functionality
- Show battery level, status, model, user assignment

### 4. Implement UsersPage (pages/UsersPage.tsx)
- Create user list table with pagination
- Add search functionality
- Add user details modal/view
- Show user stats (total swaps, total spent, bikes)
- Add wallet adjustment functionality
- Show user's bikes list

### 5. Implement AnalyticsPage (pages/AnalyticsPage.tsx)
- Add date range picker (default last 30 days)
- Create time-series charts (Recharts):
  - Swap volume over time
  - Revenue over time
  - New users over time
- Add station performance comparison table
- Add revenue breakdown by station
- Add battery health metrics dashboard
- Add export to CSV functionality

### 6. Fix Dashboard Data Mapping
- Update DashboardPage to handle correct API response structure
- Fix metrics mapping (swaps_today vs totalSwapsToday)
- Fix swap trend data structure
- Fix top stations data structure

## Testing Plan
1. Test each page loads without errors
2. Test pagination works correctly
3. Test forms submit and handle errors
4. Test data displays correctly from API
5. Test authentication/authorization
6. Test responsive design

## Priority Order
1. Fix types and API service (foundation)
2. Implement BikesPage (high visibility)
3. Implement UsersPage (admin functionality)
4. Implement AnalyticsPage (business intelligence)
5. Fix Dashboard data mapping (polish)
6. Add loading states and error handling (UX)
7. Add form validation (quality)
8. Test and deploy

## Estimated Complexity
- Types & API Service: 30 minutes
- BikesPage: 2 hours
- UsersPage: 2 hours  
- AnalyticsPage: 3 hours
- Dashboard fixes: 30 minutes
- Testing & polish: 1 hour

Total: ~9 hours of focused development
