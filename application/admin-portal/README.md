# EcoVolt Admin Portal

React-based web application for managing EcoVolt operations.

## Features

### Task 16.1: Foundation ✅
- ✅ React 18 with TypeScript
- ✅ React Router for navigation
- ✅ React Query for data fetching
- ✅ AWS Amplify for Auth and API
- ✅ Vite for fast development
- ✅ Admin authentication with Cognito
- ✅ Protected routes
- ✅ Dashboard layout with sidebar navigation

## Project Structure

```
src/
├── components/
│   └── layout/
│       ├── DashboardLayout.tsx
│       └── DashboardLayout.css
├── config/
│   └── aws-config.ts
├── hooks/
│   └── useAuth.ts
├── pages/
│   ├── auth/
│   │   ├── LoginPage.tsx
│   │   └── LoginPage.css
│   ├── DashboardPage.tsx
│   ├── StationsPage.tsx
│   ├── BikesPage.tsx
│   ├── UsersPage.tsx
│   └── AnalyticsPage.tsx
├── App.tsx
├── main.tsx
└── index.css
```

## Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

```bash
cd application/admin-portal
npm install
```

### Environment Variables

Create a `.env` file in the root directory:

```
VITE_USER_POOL_ID=your-user-pool-id
VITE_USER_POOL_CLIENT_ID=your-client-id
VITE_AWS_REGION=eu-central-1
VITE_API_URL=your-api-url
```

### Running the App

```bash
# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

The app will be available at `http://localhost:3001`

## Authentication

The admin portal requires:
- Valid Cognito user credentials
- User must be in the `admin` group

Non-admin users will be automatically signed out.

## Navigation

- **Dashboard** - Overview metrics and KPIs
- **Stations** - Manage swap stations
- **Bikes** - Fleet management
- **Users** - User management
- **Analytics** - Reports and analytics

## Technology Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **React Router** - Client-side routing
- **React Query** - Server state management
- **AWS Amplify** - Authentication and API
- **Vite** - Build tool
- **Recharts** - Data visualization (for analytics)

## Next Steps

- [ ] Implement dashboard (Task 17.1)
- [ ] Implement station management (Task 17.2)
- [ ] Implement bike fleet management (Task 17.3)
- [ ] Implement user management (Task 17.4)
- [ ] Implement analytics and reports (Task 17.5)
