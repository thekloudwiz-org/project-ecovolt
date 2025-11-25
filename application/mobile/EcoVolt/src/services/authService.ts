/**
 * Authentication Service
 * Handles all authentication operations with AWS Cognito
 */

import { signIn, signUp, confirmSignUp, signOut, resetPassword, confirmResetPassword, getCurrentUser, fetchAuthSession } from 'aws-amplify/auth';

export interface SignUpParams {
  email: string;
  password: string;
  name: string;
  phone: string;
}

export interface SignInParams {
  email: string;
  password: string;
}

export interface ConfirmSignUpParams {
  email: string;
  code: string;
}

export interface ResetPasswordParams {
  email: string;
}

export interface ConfirmResetPasswordParams {
  email: string;
  code: string;
  newPassword: string;
}

/**
 * Register a new user
 */
export const registerUser = async ({ email, password, name, phone }: SignUpParams) => {
  try {
    const { userId, nextStep } = await signUp({
      username: email,
      password,
      options: {
        userAttributes: {
          email,
          name,
          phone_number: phone,
        },
      },
    });

    return { userId, nextStep };
  } catch (error: any) {
    throw new Error(error.message || 'Registration failed');
  }
};

/**
 * Confirm user registration with verification code
 */
export const confirmRegistration = async ({ email, code }: ConfirmSignUpParams) => {
  try {
    const { isSignUpComplete, nextStep } = await confirmSignUp({
      username: email,
      confirmationCode: code,
    });

    return { isSignUpComplete, nextStep };
  } catch (error: any) {
    throw new Error(error.message || 'Verification failed');
  }
};

/**
 * Sign in user
 */
export const loginUser = async ({ email, password }: SignInParams) => {
  try {
    const { isSignedIn, nextStep } = await signIn({
      username: email,
      password,
    });

    if (isSignedIn) {
      // Get user details and tokens
      const user = await getCurrentUser();
      const session = await fetchAuthSession();

      return {
        user: {
          id: user.userId,
          email: user.signInDetails?.loginId || email,
          name: '', // Will be fetched from user attributes if needed
          phone: '',
        },
        tokens: {
          accessToken: session.tokens?.accessToken?.toString() || '',
          idToken: session.tokens?.idToken?.toString() || '',
          refreshToken: session.tokens?.refreshToken?.toString() || '',
        },
      };
    }

    return { nextStep };
  } catch (error: any) {
    throw new Error(error.message || 'Login failed');
  }
};

/**
 * Sign out user
 */
export const logoutUser = async () => {
  try {
    await signOut();
  } catch (error: any) {
    throw new Error(error.message || 'Logout failed');
  }
};

/**
 * Initiate password reset
 */
export const initiatePasswordReset = async ({ email }: ResetPasswordParams) => {
  try {
    const { nextStep } = await resetPassword({
      username: email,
    });

    return { nextStep };
  } catch (error: any) {
    throw new Error(error.message || 'Password reset initiation failed');
  }
};

/**
 * Confirm password reset with code
 */
export const confirmPasswordReset = async ({ email, code, newPassword }: ConfirmResetPasswordParams) => {
  try {
    await confirmResetPassword({
      username: email,
      confirmationCode: code,
      newPassword,
    });

    return { success: true };
  } catch (error: any) {
    throw new Error(error.message || 'Password reset confirmation failed');
  }
};

/**
 * Get current authenticated user
 */
export const getCurrentAuthUser = async () => {
  try {
    const user = await getCurrentUser();
    const session = await fetchAuthSession();

    return {
      user: {
        id: user.userId,
        email: user.signInDetails?.loginId || '',
        name: '',
        phone: '',
      },
      tokens: {
        accessToken: session.tokens?.accessToken?.toString() || '',
        idToken: session.tokens?.idToken?.toString() || '',
        refreshToken: session.tokens?.refreshToken?.toString() || '',
      },
    };
  } catch (error) {
    return null;
  }
};
