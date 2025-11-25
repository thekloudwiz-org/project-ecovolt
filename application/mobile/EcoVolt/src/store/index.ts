/**
 * Redux Store Configuration
 */

import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import stationsReducer from './slices/stationsSlice';
import swapsReducer from './slices/swapsSlice';
import bikeReducer from './slices/bikeSlice';
import walletReducer from './slices/walletSlice';
import notificationsReducer from './slices/notificationsSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    stations: stationsReducer,
    swaps: swapsReducer,
    bike: bikeReducer,
    wallet: walletReducer,
    notifications: notificationsReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
