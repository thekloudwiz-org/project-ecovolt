/**
 * AWS Amplify Configuration
 * Configure AWS services for the EcoVolt mobile app
 */

export const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: process.env.EXPO_PUBLIC_USER_POOL_ID || 'eu-central-1_E7M5G0pFZ',
      userPoolClientId: process.env.EXPO_PUBLIC_USER_POOL_CLIENT_ID || '7rqfpkbr074besmglu0pe5nnos',
      region: process.env.EXPO_PUBLIC_AWS_REGION || 'eu-central-1',
    },
  },
  API: {
    REST: {
      EcoVoltAPI: {
        endpoint: process.env.EXPO_PUBLIC_API_URL || 'https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1',
        region: process.env.EXPO_PUBLIC_AWS_REGION || 'eu-central-1',
      },
    },
  },
};
