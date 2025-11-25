/**
 * AWS Amplify Configuration
 * Configure AWS services for the EcoVolt admin portal
 */

export const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_USER_POOL_ID || 'eu-central-1_E7M5G0pFZ',
      userPoolClientId: import.meta.env.VITE_USER_POOL_CLIENT_ID || '7rqfpkbr074besmglu0pe5nnos',
      region: import.meta.env.VITE_AWS_REGION || 'eu-central-1',
    },
  },
  API: {
    REST: {
      EcoVoltAPI: {
        endpoint: import.meta.env.VITE_API_URL || 'https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1',
        region: import.meta.env.VITE_AWS_REGION || 'eu-central-1',
      },
    },
  },
}
