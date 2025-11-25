/**
 * Validation Utilities
 * Form validation helpers
 */

/**
 * Validate email format
 */
export const validateEmail = (email: string): { valid: boolean; error?: string } => {
  if (!email) {
    return { valid: false, error: 'Email is required' };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return { valid: false, error: 'Invalid email format' };
  }

  return { valid: true };
};

/**
 * Validate password strength
 * Requirements: 1.2 - Password must be at least 8 characters with uppercase, lowercase, number, and special character
 */
export const validatePassword = (password: string): { valid: boolean; error?: string } => {
  if (!password) {
    return { valid: false, error: 'Password is required' };
  }

  if (password.length < 8) {
    return { valid: false, error: 'Password must be at least 8 characters' };
  }

  if (!/[A-Z]/.test(password)) {
    return { valid: false, error: 'Password must contain an uppercase letter' };
  }

  if (!/[a-z]/.test(password)) {
    return { valid: false, error: 'Password must contain a lowercase letter' };
  }

  if (!/[0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain a number' };
  }

  if (!/[^A-Za-z0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain a special character' };
  }

  return { valid: true };
};

/**
 * Validate phone number (Ghanaian format)
 * Requirements: 15.2 - Phone number must be valid Ghanaian format
 */
export const validatePhone = (phone: string): { valid: boolean; error?: string } => {
  if (!phone) {
    return { valid: false, error: 'Phone number is required' };
  }

  // Ghanaian phone format: +233XXXXXXXXX or 0XXXXXXXXX
  const phoneRegex = /^(\+233|0)[2-9]\d{8}$/;
  if (!phoneRegex.test(phone)) {
    return { valid: false, error: 'Invalid Ghanaian phone number format' };
  }

  return { valid: true };
};

/**
 * Validate name
 */
export const validateName = (name: string): { valid: boolean; error?: string } => {
  if (!name) {
    return { valid: false, error: 'Name is required' };
  }

  if (name.length < 2) {
    return { valid: false, error: 'Name must be at least 2 characters' };
  }

  return { valid: true };
};

/**
 * Validate verification code
 */
export const validateCode = (code: string): { valid: boolean; error?: string } => {
  if (!code) {
    return { valid: false, error: 'Verification code is required' };
  }

  if (code.length !== 6) {
    return { valid: false, error: 'Verification code must be 6 digits' };
  }

  if (!/^\d+$/.test(code)) {
    return { valid: false, error: 'Verification code must contain only numbers' };
  }

  return { valid: true };
};
