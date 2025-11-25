/**
 * App Navigator
 * Main navigation structure
 */

import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useSelector } from 'react-redux';
import { RootState } from '../store';

// Auth Screens
import LoginScreen from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import VerifyEmailScreen from '../screens/auth/VerifyEmailScreen';
import ForgotPasswordScreen from '../screens/auth/ForgotPasswordScreen';

// Main Screens
import HomeScreen from '../screens/HomeScreen';
import StationMapScreen from '../screens/StationMapScreen';
import StationListScreen from '../screens/StationListScreen';
import StationDetailsScreen from '../screens/StationDetailsScreen';
import WalletScreen from '../screens/WalletScreen';
import HistoryScreen from '../screens/HistoryScreen';
import ProfileScreen from '../screens/ProfileScreen';
import BikeDetailsScreen from '../screens/BikeDetailsScreen';
import NotificationsScreen from '../screens/NotificationsScreen';

// Swap Screens
import SwapInitiationScreen from '../screens/swap/SwapInitiationScreen';
import SwapProgressScreen from '../screens/swap/SwapProgressScreen';
import SwapSuccessScreen from '../screens/swap/SwapSuccessScreen';

// Wallet Screens
import TopUpScreen from '../screens/wallet/TopUpScreen';
import TransactionHistoryScreen from '../screens/wallet/TransactionHistoryScreen';

const Stack = createNativeStackNavigator();

export default function AppNavigator() {
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated);

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {!isAuthenticated ? (
          <>
            <Stack.Screen name="Login" component={LoginScreen} />
            <Stack.Screen name="Register" component={RegisterScreen} />
            <Stack.Screen name="VerifyEmail" component={VerifyEmailScreen} />
            <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
          </>
        ) : (
          <>
            <Stack.Screen name="Home" component={HomeScreen} />
            <Stack.Screen name="StationMap" component={StationMapScreen} />
            <Stack.Screen name="StationList" component={StationListScreen} />
            <Stack.Screen name="StationDetails" component={StationDetailsScreen} />
            <Stack.Screen name="SwapInitiation" component={SwapInitiationScreen} />
            <Stack.Screen name="SwapProgress" component={SwapProgressScreen} />
            <Stack.Screen name="SwapSuccess" component={SwapSuccessScreen} />
            <Stack.Screen name="Wallet" component={WalletScreen} />
            <Stack.Screen name="TopUp" component={TopUpScreen} />
            <Stack.Screen name="TransactionHistory" component={TransactionHistoryScreen} />
            <Stack.Screen name="BikeDetails" component={BikeDetailsScreen} />
            <Stack.Screen name="Notifications" component={NotificationsScreen} />
            <Stack.Screen name="History" component={HistoryScreen} />
            <Stack.Screen name="Profile" component={ProfileScreen} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
