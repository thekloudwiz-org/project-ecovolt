# EcoVolt Frontend Documentation

## Overview

The EcoVolt frontend consists of two applications:
1. **Mobile Application** - React Native app for iOS and Android
2. **Admin Portal** - React web application for operations management

## Table of Contents

- [Mobile Application](#mobile-application)
- [Admin Portal](#admin-portal)
- [Shared Components](#shared-components)
- [State Management](#state-management)
- [API Integration](#api-integration)
- [Deployment](#deployment)

## Mobile Application

### Technology Stack

- **Framework**: React Native 0.72
- **Language**: TypeScript
- **State Management**: Redux Toolkit
- **Navigation**: React Navigation 6
- **Maps**: React Native Maps
- **Authentication**: AWS Amplify
- **UI Components**: React Native Paper
- **QR Scanner**: react-native-camera

### Features

#### 1. Authentication
- User registration with email verification
- Login with email/password
- Password reset
- Biometric authentication (Touch ID/Face ID)

#### 2. Station Finder
- Map view with station markers
- Current location tracking
- Nearby stations list
- Station details with availability
- Navigation to station

#### 3. Battery Swap Flow
- QR code scanner for station ID
- Swap initiation
- Real-time swap progress
- Completion confirmation
- Receipt generation

#### 4. Wallet
- Balance display
- Top-up with Mobile Money
- Transaction history
- Payment receipts

#### 5. Bike Monitoring
- Current bike status
- Battery level indicator
- Location tracking
- Telemetry data
- Staleness indicators

#### 6. Profile
- View/edit profile
- Phone number management
- Swap history
- Settings

#### 7. Notifications
- Push notifications
- In-app notification center
- Notification badges
- Mark as read

### Project Structure

```
application/mobile/EcoVolt/
├── src/
│   ├── screens/           # Screen components
│   │   ├── Auth/
│   │   │   ├── LoginScreen.tsx
│   │   │   ├── RegisterScreen.tsx
│   │   │   └── VerifyEmailScreen.tsx
│   │   ├── Home/
│   │   │   ├── HomeScreen.tsx
│   │   │   └── BikeStatusCard.tsx
│   │   ├── Stations/
│   │   │   ├── StationMapScreen.tsx
│   │   │   ├── StationListScreen.tsx
│   │   │   └── StationDetailsScreen.tsx
│   │   ├── Swap/
│   │   │   ├── SwapInitiateScreen.tsx
│   │   │   ├── SwapProgressScreen.tsx
│   │   │   └── SwapCompleteScreen.tsx
│   │   ├── Wallet/
│   │   │   ├── WalletScreen.tsx
│   │   │   ├── TopUpScreen.tsx
│   │   │   └── TransactionHistoryScreen.tsx
│   │   └── Profile/
│   │       ├── ProfileScreen.tsx
│   │       ├── EditProfileScreen.tsx
│   │       └── SwapHistoryScreen.tsx
│   ├── navigation/        # Navigation configuration
│   │   ├── AppNavigator.tsx
│   │   ├── AuthNavigator.tsx
│   │   └── MainNavigator.tsx
│   ├── store/             # Redux store
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   ├── stationsSlice.ts
│   │   │   ├── swapsSlice.ts
│   │   │   ├── bikeSlice.ts
│   │   │   └── walletSlice.ts
│   │   └── store.ts
│   ├── services/          # API services
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   ├── stations.ts
│   │   ├── swaps.ts
│   │   └── wallet.ts
│   ├── components/        # Reusable components
│   │   ├── StationMarker.tsx
│   │   ├── BatteryIndicator.tsx
│   │   ├── LoadingSpinner.tsx
│   │   └── ErrorBoundary.tsx
│   ├── utils/             # Utility functions
│   │   ├── location.ts
│   │   ├── validation.ts
│   │   └── formatting.ts
│   ├── types/             # TypeScript types
│   │   ├── api.ts
│   │   ├── models.ts
│   │   └── navigation.ts
│   └── config/            # Configuration
│       ├── amplify.ts
│       └── constants.ts
├── android/               # Android native code
├── ios/                   # iOS native code
├── package.json
└── tsconfig.json
```

### Setup & Development

#### Prerequisites

```bash
# Install Node.js 18+
brew install node

# Install Watchman
brew install watchman

# Install CocoaPods (for iOS)
sudo gem install cocoapods

# Install Expo CLI
npm install -g expo-cli
```

#### Installation

```bash
cd application/mobile/EcoVolt

# Install dependencies
npm install

# iOS: Install pods
cd ios && pod install && cd ..
```

#### Configuration

Create `.env` file:

```env
API_URL=https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1
AWS_REGION=eu-central-1
COGNITO_USER_POOL_ID=eu-central-1_xxxxx
COGNITO_CLIENT_ID=xxxxx
GOOGLE_MAPS_API_KEY=xxxxx
```

#### Running

```bash
# Start Metro bundler
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android

# Run on specific device
npm run ios -- --simulator="iPhone 14 Pro"
npm run android -- --deviceId=emulator-5554
```

### State Management

#### Redux Store Structure

```typescript
{
  auth: {
    user: User | null,
    tokens: {
      accessToken: string,
      idToken: string,
      refreshToken: string
    },
    isAuthenticated: boolean,
    loading: boolean,
    error: string | null
  },
  stations: {
    nearby: Station[],
    selected: Station | null,
    loading: boolean,
    error: string | null
  },
  swaps: {
    current: Swap | null,
    history: Swap[],
    loading: boolean,
    error: string | null
  },
  bike: {
    details: Bike | null,
    telemetry: Telemetry | null,
    loading: boolean,
    error: string | null
  },
  wallet: {
    balance: number,
    transactions: Transaction[],
    loading: boolean,
    error: string | null
  }
}
```

#### Example Usage

```typescript
import { useDispatch, useSelector } from 'react-redux';
import { fetchNearbyStations } from '../store/slices/stationsSlice';

function StationMapScreen() {
  const dispatch = useDispatch();
  const { nearby, loading } = useSelector((state) => state.stations);

  useEffect(() => {
    dispatch(fetchNearbyStations({ latitude: 5.6037, longitude: -0.187 }));
  }, []);

  return (
    <MapView>
      {nearby.map(station => (
        <StationMarker key={station.id} station={station} />
      ))}
    </MapView>
  );
}
```

### Building for Production

#### iOS

```bash
# Build for App Store
npm run build:ios

# Or using Expo
eas build --platform ios --profile production
```

#### Android

```bash
# Build APK
cd android
./gradlew assembleRelease

# Build AAB for Play Store
./gradlew bundleRelease

# Or using Expo
eas build --platform android --profile production
```

### Testing

```bash
# Run unit tests
npm test

# Run with coverage
npm test -- --coverage

# Run E2E tests (Detox)
npm run test:e2e:ios
npm run test:e2e:android
```

## Admin Portal

### Technology Stack

- **Framework**: React 18
- **Language**: TypeScript
- **State Management**: React Query + Context API
- **Routing**: React Router 6
- **UI Library**: Material-UI (MUI)
- **Charts**: Recharts
- **Forms**: React Hook Form
- **Authentication**: AWS Amplify

### Features

#### 1. Dashboard
- KPI cards (swaps, revenue, users, stations)
- Swap trend chart (7 days)
- Top stations table
- Recent activity feed

#### 2. Station Management
- Station list with search/filters
- Create/edit station form
- Station details view
- Battery status monitoring
- Soft delete capability

#### 3. Bike Fleet Management
- Bike list with filters
- Register new bike
- Bike details with telemetry
- Assign bike to user
- Update bike status

#### 4. User Management
- User list with search
- User details view
- Wallet balance adjustment
- User activity history
- Swap history per user

#### 5. Analytics & Reports
- Time-series charts
- Station performance comparison
- Revenue breakdown
- Battery health metrics
- Export to CSV

### Project Structure

```
application/admin-portal/
├── src/
│   ├── pages/             # Page components
│   │   ├── Dashboard/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── KPICards.tsx
│   │   │   └── SwapTrendChart.tsx
│   │   ├── Stations/
│   │   │   ├── StationList.tsx
│   │   │   ├── StationForm.tsx
│   │   │   └── StationDetails.tsx
│   │   ├── Bikes/
│   │   │   ├── BikeList.tsx
│   │   │   ├── BikeForm.tsx
│   │   │   └── BikeDetails.tsx
│   │   ├── Users/
│   │   │   ├── UserList.tsx
│   │   │   └── UserDetails.tsx
│   │   └── Analytics/
│   │       ├── Analytics.tsx
│   │       ├── StationAnalytics.tsx
│   │       └── RevenueAnalytics.tsx
│   ├── components/        # Reusable components
│   │   ├── Layout/
│   │   │   ├── AppLayout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Header.tsx
│   │   ├── Tables/
│   │   │   ├── DataTable.tsx
│   │   │   └── PaginatedTable.tsx
│   │   ├── Forms/
│   │   │   ├── FormInput.tsx
│   │   │   └── FormSelect.tsx
│   │   └── Charts/
│   │       ├── LineChart.tsx
│   │       └── BarChart.tsx
│   ├── hooks/             # Custom hooks
│   │   ├── useAuth.ts
│   │   ├── useStations.ts
│   │   ├── useBikes.ts
│   │   └── useAnalytics.ts
│   ├── services/          # API services
│   │   ├── api.ts
│   │   ├── admin.ts
│   │   └── analytics.ts
│   ├── contexts/          # React contexts
│   │   └── AuthContext.tsx
│   ├── utils/             # Utilities
│   │   ├── formatting.ts
│   │   └── validation.ts
│   ├── types/             # TypeScript types
│   │   └── index.ts
│   └── config/            # Configuration
│       └── amplify.ts
├── public/
├── package.json
└── tsconfig.json
```

### Setup & Development

#### Installation

```bash
cd application/admin-portal

# Install dependencies
npm install
```

#### Configuration

Create `.env` file:

```env
VITE_API_URL=https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1
VITE_AWS_REGION=eu-central-1
VITE_COGNITO_USER_POOL_ID=eu-central-1_xxxxx
VITE_COGNITO_CLIENT_ID=xxxxx
```

#### Running

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Data Fetching with React Query

```typescript
import { useQuery } from '@tanstack/react-query';
import { getDashboardMetrics } from '../services/admin';

function Dashboard() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['dashboard'],
    queryFn: getDashboardMetrics,
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={3}>
        <KPICard title="Total Swaps" value={data.totalSwapsToday} />
      </Grid>
      {/* More KPI cards */}
    </Grid>
  );
}
```

### Building for Production

```bash
# Build
npm run build

# Output directory: dist/

# Deploy to S3
aws s3 sync dist/ s3://ecovolt-admin-portal --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### Testing

```bash
# Run unit tests
npm test

# Run with coverage
npm test -- --coverage

# Run E2E tests (Playwright)
npm run test:e2e
```

## Shared Components

### API Client

Both applications use a shared API client configuration:

```typescript
import axios from 'axios';
import { Auth } from 'aws-amplify';

const api = axios.create({
  baseURL: process.env.API_URL,
  timeout: 10000,
});

// Request interceptor to add auth token
api.interceptors.request.use(async (config) => {
  const session = await Auth.currentSession();
  const token = session.getAccessToken().getJwtToken();
  config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired, refresh
      await Auth.currentSession();
      return api.request(error.config);
    }
    return Promise.reject(error);
  }
);

export default api;
```

### Authentication Flow

```typescript
import { Auth } from 'aws-amplify';

// Login
async function login(email: string, password: string) {
  const user = await Auth.signIn(email, password);
  return user;
}

// Register
async function register(email: string, password: string, name: string) {
  const { user } = await Auth.signUp({
    username: email,
    password,
    attributes: {
      email,
      name,
    },
  });
  return user;
}

// Confirm email
async function confirmEmail(email: string, code: string) {
  await Auth.confirmSignUp(email, code);
}

// Logout
async function logout() {
  await Auth.signOut();
}
```

## API Integration

### Service Layer Pattern

```typescript
// services/stations.ts
import api from './api';
import { Station } from '../types';

export const stationsService = {
  async getNearby(latitude: number, longitude: number, radius: number = 10): Promise<Station[]> {
    const response = await api.get('/stations/nearby', {
      params: { latitude, longitude, radius },
    });
    return response.data.stations;
  },

  async getById(stationId: string): Promise<Station> {
    const response = await api.get(`/stations/${stationId}`);
    return response.data.station;
  },

  async getAvailability(stationId: string): Promise<number> {
    const response = await api.get(`/stations/${stationId}/availability`);
    return response.data.availableBatteries;
  },
};
```

### Error Handling

```typescript
import { AxiosError } from 'axios';

function handleApiError(error: unknown): string {
  if (error instanceof AxiosError) {
    if (error.response) {
      // Server responded with error
      return error.response.data.error?.message || 'An error occurred';
    } else if (error.request) {
      // Request made but no response
      return 'Network error. Please check your connection.';
    }
  }
  return 'An unexpected error occurred';
}
```

## Deployment

### Mobile App Deployment

#### iOS App Store

1. **Prepare**:
   - Update version in `ios/EcoVolt/Info.plist`
   - Create app icons and screenshots
   - Prepare App Store listing

2. **Build**:
   ```bash
   eas build --platform ios --profile production
   ```

3. **Submit**:
   - Download IPA from Expo
   - Upload to App Store Connect
   - Submit for review

#### Google Play Store

1. **Prepare**:
   - Update version in `android/app/build.gradle`
   - Create app icons and screenshots
   - Prepare Play Store listing

2. **Build**:
   ```bash
   eas build --platform android --profile production
   ```

3. **Submit**:
   - Download AAB from Expo
   - Upload to Google Play Console
   - Submit for review

### Admin Portal Deployment

#### S3 + CloudFront

```bash
# Build
npm run build

# Deploy to S3
aws s3 sync dist/ s3://ecovolt-admin-portal \
  --delete \
  --cache-control "public, max-age=31536000, immutable"

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

#### Vercel (Alternative)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

## Support

- **Mobile App Issues**: mobile-support@ecovolt.com
- **Admin Portal Issues**: admin-support@ecovolt.com
- **Documentation**: See [docs/](../docs/)

---

**Last Updated**: November 2024  
**Mobile App Version**: 1.0.0  
**Admin Portal Version**: 1.0.0

