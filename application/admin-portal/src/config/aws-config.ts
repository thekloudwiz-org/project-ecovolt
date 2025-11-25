/**
 * AWS Amplify Configuration
 * Configure AWS services for the EcoVolt admin portal
 */

export const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_USER_POOL_ID,
      userPoolClientId: import.meta.env.VITE_USER_POOL_CLIENT_ID,
      region: import.meta.env.VITE_AWS_REGION || 'eu-central-1',
    },
  },
  API: {
    REST: {
      EcoVoltAPI: {
        endpoint: import.meta.env.VITE_API_URL,
        region: import.meta.env.VITE_AWS_REGION || 'eu-central-1',
      },
    },
  },
}
