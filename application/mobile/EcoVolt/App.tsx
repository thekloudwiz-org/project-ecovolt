/**
 * EcoVolt Mobile App
 * Main entry point
 */

import React from 'react';
import { Provider } from 'react-redux';
import { Amplify } from 'aws-amplify';
import { store } from './src/store';
import { awsConfig } from './src/config/aws-config';
import AppNavigator from './src/navigation/AppNavigator';

// Configure AWS Amplify
Amplify.configure(awsConfig);

export default function App() {
  return (
    <Provider store={store}>
      <AppNavigator />
    </Provider>
  );
}
