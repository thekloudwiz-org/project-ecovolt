/**
 * Forgot Password Screen
 * Allows users to reset their password
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { initiatePasswordReset, confirmPasswordReset } from '../../services/authService';
import { validateEmail, validateCode, validatePassword } from '../../utils/validation';
import Input from '../../components/Input';
import Button from '../../components/Button';

export default function ForgotPasswordScreen({ navigation }: any) {
  const [step, setStep] = useState<'email' | 'reset'>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errors, setErrors] = useState<{
    email?: string;
    code?: string;
    newPassword?: string;
    confirmPassword?: string;
  }>({});
  const [loading, setLoading] = useState(false);

  const handleSendCode = async () => {
    // Validate email
    const emailValidation = validateEmail(email);

    if (!emailValidation.valid) {
      setErrors({ email: emailValidation.error });
      return;
    }

    setErrors({});
    setLoading(true);

    try {
      await initiatePasswordReset({ email });
      Alert.alert('Code Sent', 'A password reset code has been sent to your email.');
      setStep('reset');
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async () => {
    // Validate inputs
    const codeValidation = validateCode(code);
    const passwordValidation = validatePassword(newPassword);

    const newErrors: any = {};

    if (!codeValidation.valid) newErrors.code = codeValidation.error;
    if (!passwordValidation.valid) newErrors.newPassword = passwordValidation.error;

    if (newPassword !== confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setErrors({});
    setLoading(true);

    try {
      await confirmPasswordReset({ email, code, newPassword });

      Alert.alert(
        'Password Reset Successful',
        'Your password has been reset. You can now login with your new password.',
        [
          {
            text: 'OK',
            onPress: () => navigation.navigate('Login'),
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.icon}>🔒</Text>
          <Text style={styles.title}>
            {step === 'email' ? 'Forgot Password?' : 'Reset Password'}
          </Text>
          <Text style={styles.subtitle}>
            {step === 'email'
              ? 'Enter your email to receive a reset code'
              : 'Enter the code and your new password'}
          </Text>
        </View>

        <View style={styles.form}>
          {step === 'email' ? (
            <>
              <Input
                label="Email"
                value={email}
                onChangeText={setEmail}
                placeholder="Enter your email"
                keyboardType="email-address"
                error={errors.email}
              />

              <Button title="Send Reset Code" onPress={handleSendCode} loading={loading} />
            </>
          ) : (
            <>
              <Input
                label="Verification Code"
                value={code}
                onChangeText={setCode}
                placeholder="Enter 6-digit code"
                keyboardType="numeric"
                error={errors.code}
              />

              <Input
                label="New Password"
                value={newPassword}
                onChangeText={setNewPassword}
                placeholder="Enter new password"
                secureTextEntry
                error={errors.newPassword}
              />

              <Input
                label="Confirm New Password"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                placeholder="Confirm new password"
                secureTextEntry
                error={errors.confirmPassword}
              />

              <Text style={styles.passwordHint}>
                Password must be at least 8 characters with uppercase, lowercase, number, and special character
              </Text>

              <Button title="Reset Password" onPress={handleResetPassword} loading={loading} />
            </>
          )}
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  icon: {
    fontSize: 64,
    marginBottom: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    lineHeight: 24,
  },
  form: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  passwordHint: {
    fontSize: 12,
    color: '#666',
    marginBottom: 16,
    fontStyle: 'italic',
  },
});
