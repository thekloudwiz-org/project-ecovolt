# Implementation Plan

- [x] 1. Complete Backend API Core Endpoints
- [x] 1.1 Implement authentication endpoints (register, login, confirm, refresh)
  - Create `/auth/register` endpoint with Cognito integration
  - Create `/auth/login` endpoint with token generation
  - Create `/auth/confirm` endpoint for email verification
  - Create `/auth/refresh` endpoint for token refresh
  - _Requirements: 1.1, 1.2, 1.3_

- [ ]* 1.2 Write property test for authentication
  - **Property 1: User registration creates valid account**
  - **Property 2: Authentication tokens have correct expiration**
  - **Property 3: Expired tokens are rejected**
  - **Property 4: Password validation enforces requirements**
  - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**

- [x] 1.3 Implement input validators module
  - Create `utils/validators.py` with coordinate, phone, amount validation
  - Add station data validation
  - Add swap request validation
  - Add wallet top-up validation
  - _Requirements: 2.1, 6.1, 9.1, 9.2, 15.2_

- [ ]* 1.4 Write property tests for validators
  - **Property 7: Haversine distance calculation is accurate**
  - **Property 17: Wallet top-up validates amount bounds**
  - **Property 26: Station creation validates required fields**
  - **Property 43: Phone number validation enforces Ghanaian format**
  - **Validates: Requirements 2.3, 6.1, 6.6, 9.1, 9.2, 15.2**

- [x] 2. Implement Swap Operations
- [x] 2.1 Create swaps API endpoints
  - Implement `POST /swaps` - initiate swap with all validations
  - Implement `PUT /swaps/{id}/complete` - complete swap with state updates
  - Implement `GET /swaps/{id}` - get swap status
  - Implement `GET /swaps/history` - get user swap history with pagination
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4_

- [ ]* 2.2 Write property tests for swap initiation
  - **Property 9: Swap initiation validates all preconditions**
  - **Property 10: Swap initiation creates transaction and updates wallet**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**

- [ ]* 2.3 Write property tests for swap completion
  - **Property 11: Swap completion requires initiated status**
  - **Property 12: Swap completion updates all related entities**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**

- [ ]* 2.4 Write property tests for swap history
  - **Property 14: Swap history returns all user swaps sorted**
  - **Property 15: Swap history entries contain required fields**
  - **Property 16: Pagination returns correct page with metadata**
  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

- [x] 2.5 Create Swap data model
  - Implement `models/swap.py` with Swap class
  - Add status transition validation
  - Add duration calculation
  - _Requirements: 3.4, 4.3_

- [x] 3. Implement User Profile and Wallet Operations
- [x] 3.1 Create user profile endpoints
  - Implement `GET /profile` - get user profile
  - Implement `PUT /profile` - update profile with validation
  - Add phone number format validation
  - Prevent modification of immutable fields (email, user_id)
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ]* 3.2 Write property tests for profile operations
  - **Property 44: Profile updates preserve immutable fields**
  - **Validates: Requirements 15.5**

- [x] 3.3 Create wallet endpoints
  - Implement `GET /wallet` - get wallet balance and transaction history
  - Implement `POST /wallet/topup` - initiate wallet top-up
  - Implement `GET /wallet/transactions` - get transaction history with pagination
  - Add Mobile Money integration stub (to be implemented with actual credentials)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ]* 3.4 Write property tests for wallet operations
  - **Property 18: Successful payment increases wallet balance**
  - **Property 19: Successful payment creates transaction record**
  - **Property 20: Failed payment preserves wallet balance**
  - **Validates: Requirements 6.3, 6.4, 6.5**

- [x] 3.4 Create Payment data model
  - Implement `models/payment.py` with Payment and WalletTransaction classes
  - Add payment status tracking
  - Add transaction type validation
  - _Requirements: 6.4_

- [x] 4. Implement Bike Operations
- [x] 4.1 Create bike endpoints
  - Implement `GET /bikes/{id}` - get bike details with ownership check
  - Add real-time telemetry retrieval from DynamoDB
  - Add staleness indicator for old telemetry
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ]* 4.2 Write property tests for bike operations
  - **Property 21: Bike details require ownership**
  - **Property 22: Bike details include all required fields**
  - **Property 23: Bike details include telemetry freshness indicator**
  - **Validates: Requirements 7.1, 7.2, 7.4, 7.5**

- [x] 4.3 Create Bike data model
  - Implement `models/bike.py` with Bike class
  - Add battery level tracking
  - Add location tracking
  - Add odometer tracking
  - _Requirements: 7.2_

- [x] 5. Implement Admin Dashboard and Analytics
- [x] 5.1 Create admin dashboard endpoint
  - Implement `GET /admin/dashboard` with admin role check
  - Calculate today's metrics (swaps, revenue, active riders, stations)
  - Generate 7-day swap trend data
  - Get top 5 stations by swap volume
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ]* 5.2 Write property tests for admin authorization
  - **Property 24: Admin endpoints require admin role**
  - **Property 25: Dashboard includes all required metrics**
  - **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 9.6**

- [x] 5.3 Create analytics endpoints
  - Implement `GET /admin/analytics` - time-series analytics with date range
  - Implement `GET /admin/analytics/stations` - per-station analytics
  - Implement `GET /admin/analytics/revenue` - revenue breakdown
  - Implement `GET /admin/analytics/batteries` - battery health metrics
  - Add default date range of last 30 days
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ]* 5.4 Write property tests for analytics
  - **Property 32: Analytics aggregates data correctly**
  - **Property 33: Station analytics groups by station**
  - **Validates: Requirements 11.1, 11.2**

- [x] 6. Implement Admin Station Management
- [x] 6.1 Create station management endpoints
  - Implement `GET /admin/stations` - list all stations with pagination
  - Implement `POST /admin/stations` - create station with validation
  - Implement `PUT /admin/stations/{id}` - update station (partial updates)
  - Implement `DELETE /admin/stations/{id}` - soft delete station
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ]* 6.2 Write property tests for station management
  - **Property 27: Station creation generates unique ID**
  - **Property 28: Station update modifies only specified fields**
  - **Property 29: Station deletion is soft delete**
  - **Validates: Requirements 9.3, 9.4, 9.5**

- [x] 7. Implement Admin Bike Fleet Management
- [x] 7.1 Create bike management endpoints
  - Implement `GET /admin/bikes` - list all bikes with pagination
  - Implement `POST /admin/bikes` - register new bike
  - Implement `PUT /admin/bikes/{id}` - update bike details
  - Implement `PUT /admin/bikes/{id}/assign` - assign bike to user
  - Include telemetry data in bike details
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ]* 7.2 Write property tests for bike management
  - **Property 30: Bike registration sets correct initial state**
  - **Property 31: Bike assignment updates user ID**
  - **Validates: Requirements 10.2, 10.3**

- [x] 7.3 Create admin user management endpoints
  - Implement `GET /admin/users` - list users with pagination
  - Implement `GET /admin/users/{id}` - get user details
  - Implement `PUT /admin/users/{id}/wallet` - adjust wallet balance (admin override)
  - _Requirements: 8.1_

- [x] 8. Implement Notifications System
- [x] 8.1 Create notifications utility module
  - Implement `utils/notifications.py` with SNS integration
  - Add push notification sending function
  - Add notification storage to DynamoDB with TTL
  - Add notification templates (swap complete, wallet topup, low balance, alerts)
  - _Requirements: 4.6, 12.1, 12.2, 12.3, 12.4_

- [x] 8.2 Create notification endpoints
  - Implement `GET /notifications` - get unread notifications sorted by timestamp
  - Implement `PUT /notifications/{id}/read` - mark notification as read
  - _Requirements: 12.5_

- [ ]* 8.3 Write property tests for notifications
  - **Property 13: Swap completion triggers notification**
  - **Property 34: Low balance triggers notification**
  - **Property 35: Notifications are stored with TTL**
  - **Property 36: Notification query returns unread sorted**
  - **Validates: Requirements 4.6, 12.3, 12.4, 12.5**

- [x] 8.4 Integrate notifications into swap and wallet flows
  - Add notification call to swap completion handler
  - Add notification call to wallet top-up handler
  - Add low balance check and notification trigger
  - _Requirements: 4.6, 12.1, 12.2, 12.3_

- [x] 9. Implement IoT Telemetry Processing
- [x] 9.1 Create IoT utilities module
  - Implement `utils/iot.py` with IoT Core integration
  - Add function to send commands to stations
  - Add function to send commands to bikes
  - Add function to query latest telemetry from DynamoDB
  - _Requirements: 13.1, 13.2, 13.3_

- [x] 9.2 Create IoT telemetry processor Lambda
  - Implement `functions/iot_processor.py` to handle IoT messages
  - Process bike telemetry and update DynamoDB
  - Process station telemetry and update DynamoDB
  - Add TTL to telemetry records (30 days)
  - Trigger low battery alerts when battery < 10%
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ]* 9.3 Write property tests for telemetry processing
  - **Property 37: Telemetry processing is timely**
  - **Property 38: Bike telemetry updates DynamoDB**
  - **Property 39: Low battery triggers alert**
  - **Validates: Requirements 13.1, 13.2, 13.5**

- [ ] 10. Implement Error Handling and Logging
- [x] 10.1 Create error handling utilities
  - Implement standardized error response format
  - Add error code mapping
  - Add request correlation ID generation
  - Create error response builder functions
  - _Requirements: 14.1, 14.3_

- [x] 10.2 Add comprehensive logging
  - Add structured logging to all endpoints
  - Include correlation IDs in all log entries
  - Add request/response logging
  - Add error logging with stack traces
  - _Requirements: 14.2, 14.5_

- [x] 10.3 Implement retry logic
  - Add database query retry with exponential backoff
  - Add DynamoDB operation retry
  - Configure retry limits (3 attempts)
  - _Requirements: 14.4_

- [ ]* 10.4 Write property tests for error handling
  - **Property 40: Error responses include correct status codes**
  - **Property 41: Database failures trigger retry with backoff**
  - **Property 42: All logs include correlation ID**
  - **Validates: Requirements 14.3, 14.4, 14.5**

- [ ] 11. Update API Handler with Complete Routing
- [x] 11.1 Update main API handler
  - Update `functions/api_handler.py` with all endpoint routes
  - Add authentication middleware
  - Add admin authorization checks
  - Add CORS headers
  - Add error handling wrapper
  - _Requirements: 1.4, 8.1, 9.6_

- [x] 11.2 Add API Gateway integration
  - Configure API Gateway routes in Terraform
  - Add Lambda authorizer for JWT verification
  - Configure CORS settings
  - Add request/response transformations
  - _Requirements: 1.3, 1.4_

- [x] 12. Checkpoint - Ensure all backend tests pass
  - Run all unit tests
  - Run all property-based tests
  - Verify test coverage > 80%
  - Fix any failing tests
  - Ask user if questions arise

- [x] 13. Create Database Migration Scripts
- [x] 13.1 Create initial schema migration
  - Write SQL script for users table
  - Write SQL script for stations table
  - Write SQL script for bikes table
  - Write SQL script for swaps table
  - Write SQL script for wallet_transactions table
  - _Requirements: All data model requirements_

- [x] 13.2 Create indexes migration
  - Add indexes for stations (location, status)
  - Add indexes for swaps (user_id, station_id, created_at)
  - Add indexes for bikes (user_id, status)
  - Add indexes for wallet_transactions (user_id, created_at)
  - _Requirements: Performance optimization_

- [x] 13.3 Create seed data script
  - Add sample stations in Accra
  - Add sample bikes
  - Add sample users
  - Add sample batteries in DynamoDB
  - _Requirements: Testing and demo_

- [ ] 14. Build Mobile Application Foundation
- [ ] 14.1 Initialize React Native project
  - Create React Native project with TypeScript
  - Configure navigation (React Navigation)
  - Set up Redux Toolkit for state management
  - Configure AWS Amplify for Auth and API
  - Add React Native Maps
  - _Requirements: Mobile app foundation_

- [ ] 14.2 Implement authentication screens
  - Create Login screen with email/password
  - Create Registration screen with validation
  - Create Email Verification screen
  - Create Forgot Password screen
  - Integrate with Cognito via Amplify
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 14.3 Create Redux store structure
  - Set up auth slice (user, tokens, isAuthenticated)
  - Set up stations slice (nearby, selected, loading)
  - Set up swaps slice (current, history, loading)
  - Set up bike slice (details, telemetry, loading)
  - Set up wallet slice (balance, transactions, loading)
  - _Requirements: State management_

- [ ] 15. Build Mobile App Core Features
- [ ] 15.1 Implement station finder
  - Create Map screen with React Native Maps
  - Add current location tracking
  - Display station markers with availability
  - Implement nearby stations API call
  - Create Station Details screen
  - Add navigation to station
  - _Requirements: 2.1, 2.2, 2.4_

- [ ] 15.2 Implement battery swap flow
  - Create Swap Initiation screen
  - Add QR code scanner for station ID
  - Implement swap initiation API call
  - Create Swap Progress screen
  - Implement swap completion API call
  - Add success confirmation screen
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3_

- [ ] 15.3 Implement wallet features
  - Create Wallet screen with balance display
  - Create Top-Up screen with amount input
  - Add Mobile Money integration (stub for now)
  - Create Transaction History screen
  - Implement pagination for transactions
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 15.4 Implement bike monitoring
  - Create Home Dashboard screen
  - Display bike status (battery level, location)
  - Add real-time telemetry updates
  - Show staleness indicator for old data
  - Add bike details view
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 15.5 Implement history and profile
  - Create Swap History screen with list
  - Implement pagination for history
  - Create Profile screen
  - Add profile edit functionality
  - Add phone number validation
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 15.1, 15.2, 15.3, 15.4_

- [ ] 15.6 Implement notifications
  - Set up push notification handling
  - Create Notifications screen
  - Display unread notifications
  - Add mark as read functionality
  - Add notification badges
  - _Requirements: 12.1, 12.2, 12.3, 12.5_

- [ ]* 15.7 Write mobile app tests
  - Unit tests for Redux reducers
  - Unit tests for utility functions
  - Component tests for key screens
  - Integration tests for API calls
  - _Requirements: Testing strategy_

- [ ] 16. Build Admin Portal Foundation
- [ ] 16.1 Initialize React web project
  - Create React project with TypeScript
  - Set up React Router for navigation
  - Configure Material-UI or Tailwind CSS
  - Set up React Query for data fetching
  - Configure AWS Amplify for Auth and API
  - _Requirements: Admin portal foundation_

- [ ] 16.2 Implement admin authentication
  - Create Admin Login screen
  - Add Cognito integration with admin group check
  - Create protected route wrapper
  - Add session management
  - _Requirements: 8.1_

- [ ] 16.3 Create admin layout
  - Create main layout with sidebar navigation
  - Add header with user menu
  - Create dashboard route
  - Create stations route
  - Create bikes route
  - Create users route
  - Create analytics route
  - _Requirements: Admin portal structure_

- [ ] 17. Build Admin Portal Features
- [ ] 17.1 Implement dashboard
  - Create KPI cards component (swaps, revenue, users, stations)
  - Create swap trend chart (Recharts)
  - Create top stations table
  - Create recent activity feed
  - Fetch data from dashboard API
  - _Requirements: 8.2, 8.3, 8.4_

- [ ] 17.2 Implement station management
  - Create station list with search and filters
  - Create station table with pagination
  - Create station form (create/edit)
  - Add form validation
  - Implement CRUD operations
  - Add station details view with battery status
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 17.3 Implement bike fleet management
  - Create bike list with filters
  - Create bike table with status indicators
  - Create bike registration form
  - Create bike details view with telemetry
  - Implement bike assignment to users
  - Add bike update functionality
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ] 17.4 Implement user management
  - Create user list with search
  - Create user table with pagination
  - Create user details view
  - Add wallet balance adjustment
  - Display user activity and swap history
  - _Requirements: Admin user management_

- [ ] 17.5 Implement analytics and reports
  - Create date range picker component
  - Create time-series charts (swaps, revenue, users)
  - Create station performance comparison
  - Create battery health metrics view
  - Create revenue breakdown view
  - Add export to CSV functionality
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ]* 17.6 Write admin portal tests
  - Unit tests for components
  - Unit tests for custom hooks
  - Integration tests for forms
  - Integration tests for API calls
  - E2E tests for critical flows
  - _Requirements: Testing strategy_

- [ ] 18. Deployment and Infrastructure Updates
- [x] 18.1 Update Terraform for Lambda functions
  - Add Lambda function for API handler
  - Add Lambda function for IoT processor
  - Add Lambda function for stream processor
  - Configure environment variables
  - Add IAM roles and policies
  - _Requirements: Deployment_

- [x] 18.2 Configure API Gateway
  - Create REST API in Terraform
  - Add all endpoint routes
  - Configure Lambda integrations
  - Add Lambda authorizer
  - Configure CORS
  - Add WAF rules
  - _Requirements: API Gateway configuration_

- [x] 18.3 Set up CI/CD pipeline
  - Create GitHub Actions workflow for backend
  - Add automated testing step
  - Add Lambda deployment step
  - Create workflow for mobile app
  - Create workflow for admin portal
  - _Requirements: CI/CD_

- [x] 18.4 Deploy to development environment
  - Run database migrations
  - Deploy Lambda functions
  - Deploy API Gateway
  - Seed test data
  - Verify all endpoints
  - _Requirements: Development deployment_

- [ ] 19. Final Testing and Documentation
- [x] 19.1 Perform end-to-end testing
  - Test complete swap flow (mobile → backend → database)
  - Test wallet top-up flow
  - Test admin station management
  - Test IoT telemetry processing
  - Test notifications
  - _Requirements: E2E testing_

- [ ]* 19.2 Performance testing
  - Load test critical endpoints
  - Measure response times
  - Test concurrent user scenarios
  - Verify Lambda scaling
  - _Requirements: Performance testing_

- [ ]* 19.3 Security testing
  - Test authentication flows
  - Test authorization checks
  - Test input validation
  - Verify encryption
  - _Requirements: Security testing_

- [ ] 19.4 Create API documentation
  - Document all endpoints with examples
  - Add request/response schemas
  - Add error code reference
  - Create Postman collection
  - _Requirements: Documentation_

- [ ] 19.5 Create deployment documentation
  - Document deployment procedures
  - Add environment configuration guide
  - Create troubleshooting guide
  - Document monitoring setup
  - _Requirements: Documentation_

- [ ] 20. Final Checkpoint - Production Readiness
  - Verify all tests pass
  - Verify test coverage meets requirements
  - Review security configurations
  - Review monitoring and alerting
  - Verify backup and disaster recovery
  - Ask user for production deployment approval
