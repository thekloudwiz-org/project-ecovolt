# EcoVolt Mobile App

React Native mobile application for the EcoVolt battery swapping platform.

## Features Implemented

### Authentication (Task 14.2)
- ✅ Login screen with email/password
- ✅ Registration screen with validation
- ✅ Email verification screen
- ✅ Forgot password screen
- ✅ AWS Cognito integration via Amplify
- ✅ Form validation (email, password, phone)
- ✅ Redux state management for auth

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── Button.tsx      # Button with loading state
│   └── Input.tsx       # Text input with validation
├── config/             # Configuration files
│   └── aws-config.ts   # AWS Amplify configuration
├── navigation/         # Navigation setup
│   └── AppNavigator.tsx # Main navigation with auth flow
├── screens/            # Screen components
│   ├── auth/          # Authentication screens
│   │   ├── LoginScreen.tsx
│   │   ├── RegisterScreen.tsx
│   │   ├── VerifyEmailScreen.tsx
│   │   └── ForgotPasswordScreen.tsx
│   └── HomeScreen.tsx
├── services/           # API and service integrations
│   └── authService.ts  # Cognito authentication service
├── store/              # Redux store
│   ├── index.ts       # Store configuration
│   └── slices/        # Redux slices
│       ├── authSlice.ts
│       ├── stationsSlice.ts
│       ├── swapsSlice.ts
│       ├── bikeSlice.ts
│       └── walletSlice.ts
├── types/              # TypeScript type definitions
└── utils/              # Utility functions
    └── validation.ts   # Form validation helpers
```

## Getting Started

### Prerequisites
- Node.js 18+
- Expo CLI
- iOS Simulator (Mac) or Android Emulator

### Installation

```bash
cd application/mobile/EcoVolt
npm install
```

### Running the App

```bash
# Start Expo development server
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android
```

## Environment Variables

Create a `.env` file in the root directory:

```
EXPO_PUBLIC_USER_POOL_ID=your-user-pool-id
EXPO_PUBLIC_USER_POOL_CLIENT_ID=your-client-id
EXPO_PUBLIC_AWS_REGION=eu-central-1
EXPO_PUBLIC_API_URL=your-api-url
```

## Authentication Flow

1. **Registration**
   - User enters name, email, phone, and password
   - Phone number validated for Ghanaian format (+233XXXXXXXXX)
   - Password validated for complexity requirements
   - Cognito sends verification code to email

2. **Email Verification**
   - User enters 6-digit code from email
   - Account is confirmed in Cognito

3. **Login**
   - User enters email and password
   - Cognito returns JWT tokens
   - Tokens stored in Redux state

4. **Password Reset**
   - User enters email
   - Cognito sends reset code
   - User enters code and new password

## Validation Rules

### Email
- Valid email format required

### Password
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

### Phone Number
- Ghanaian format: +233XXXXXXXXX or 0XXXXXXXXX
- Automatically converts 0XXXXXXXXX to +233XXXXXXXXX

## Station Finder (Task 15.1) ✅

The station finder feature allows riders to locate nearby battery swap stations:

### Features
- **Map View** - Interactive map showing all nearby stations within 10km
- **Station Markers** - Color-coded markers indicating availability:
  - 🟢 Green: Available (3+ batteries)
  - 🟠 Orange: Low stock (1-2 batteries)
  - 🔴 Red: Empty (0 batteries)
  - ⚫ Gray: Closed/Inactive
- **List View** - Alternative list view with distance sorting
- **Station Details** - Detailed information including:
  - Real-time battery availability
  - Operating hours
  - Swap cost
  - Distance from user
  - Recent swap activity
  - Navigation integration
- **Location Tracking** - Automatic user location detection
- **Refresh** - Pull-to-refresh for latest data

### Screens
- `StationMapScreen.tsx` - Map view with markers
- `StationListScreen.tsx` - List view with sorting
- `StationDetailsScreen.tsx` - Detailed station information

### API Integration
- `GET /stations/nearby` - Fetch stations within radius
- `GET /stations/{id}` - Get station details

## Battery Swap Flow (Task 15.2) ✅

The battery swap flow allows riders to exchange depleted batteries for charged ones:

### Features
- **Swap Initiation** - Start a swap at a selected station
  - Bike ID input with QR code scanner option
  - Real-time battery availability check
  - Wallet balance verification
  - Cost confirmation
  - Battery reservation
- **Swap Progress** - Track ongoing swap
  - Real-time status updates
  - Swap details display
  - Step-by-step instructions
  - Refresh capability
  - Cancel option
- **Swap Completion** - Finalize the swap
  - Physical swap confirmation
  - Status update to completed
  - Duration tracking
  - Success confirmation
- **Swap Success** - Post-swap summary
  - Swap summary with all details
  - Tips for battery maintenance
  - Quick navigation to history

### Screens
- `SwapInitiationScreen.tsx` - Initiate swap with validation
- `SwapProgressScreen.tsx` - Track and complete swap
- `SwapSuccessScreen.tsx` - Success confirmation

### API Integration
- `POST /swaps` - Initiate swap
- `PUT /swaps/{id}/complete` - Complete swap
- `GET /swaps/{id}` - Get swap status

### Requirements Satisfied
- ✅ 3.1-3.7 - Swap initiation with all validations
- ✅ 4.1-4.5 - Swap completion with state updates
- ✅ Wallet balance verification
- ✅ Battery reservation
- ✅ Real-time status tracking

## Wallet Features (Task 15.3) ✅

Complete wallet management with Mobile Money integration:

### Features
- **Wallet Balance** - Real-time balance display
- **Top-Up** - Mobile Money integration (MTN, Vodafone, AirtelTigo)
- **Transaction History** - Complete transaction list with filtering
- **Quick Stats** - Transaction counts by type
- **Amount Validation** - Min GHS 10, Max GHS 1000

### Screens
- `WalletScreen.tsx` - Balance and recent transactions
- `TopUpScreen.tsx` - Mobile Money top-up
- `TransactionHistoryScreen.tsx` - Full transaction history

### Requirements Satisfied
- ✅ 6.1-6.6 - Wallet operations and Mobile Money integration

## Bike Monitoring (Task 15.4) ✅

Real-time bike status and telemetry monitoring:

### Features
- **Dashboard Display** - Bike status on home screen
- **Battery Level** - Real-time battery percentage with color coding
- **Telemetry Data** - Speed, odometer, temperature, location
- **Staleness Indicator** - Warning for outdated data (>5 min)
- **Detailed View** - Complete bike information screen

### Screens
- `HomeScreen.tsx` - Updated with bike status card
- `BikeDetailsScreen.tsx` - Detailed bike information

### Requirements Satisfied
- ✅ 7.1-7.5 - Bike details with ownership check and telemetry

## History and Profile (Task 15.5) ✅

Swap history and user profile management:

### Features
- **Swap History** - Complete list of past swaps
- **Status Indicators** - Color-coded swap status
- **Pagination** - Efficient data loading
- **Profile Management** - Edit name and phone
- **Account Actions** - Settings and logout

### Screens
- `HistoryScreen.tsx` - Swap history with pagination
- `ProfileScreen.tsx` - User profile with edit mode

### Requirements Satisfied
- ✅ 5.1-5.4 - Swap history with pagination
- ✅ 15.1-15.5 - Profile management

## Notifications (Task 15.6) ✅

Push notification system with mark as read:

### Features
- **Notification List** - All notifications sorted by timestamp
- **Unread Badge** - Count of unread notifications
- **Mark as Read** - Tap to mark individual notifications
- **Type Icons** - Visual indicators for notification types
- **Deep Linking** - Navigate to relevant screens from notifications

### Screens
- `NotificationsScreen.tsx` - Notification list with actions

### Requirements Satisfied
- ✅ 12.1-12.5 - Notification system with storage and display

## Summary

All mobile app core features (Tasks 15.1-15.6) have been successfully implemented:

✅ Station Finder - Map and list views with real-time availability
✅ Battery Swap Flow - Complete multi-step swap process
✅ Wallet Features - Balance, top-up, and transaction history
✅ Bike Monitoring - Real-time telemetry and status
✅ History & Profile - Swap history and user management
✅ Notifications - Push notifications with mark as read

The EcoVolt mobile app is now feature-complete with all core functionality implemented and ready for testing.
