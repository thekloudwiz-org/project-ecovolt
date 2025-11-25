/**
 * Registration Screen
 * Requirements: 1.1, 1.2, 15.2
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { registerUser } from '../../services/authService';
import { validateEmail, validatePassword, validateName, validatePhone } from '../../utils/validation';
import Input from '../../components/Input';
import Button from '../../components/Button';

export default function RegisterScreen({ navigation }: any) {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
  });
  const [errors, setErrors] = useState<{
    name?: string;
    email?: string;
    phone?: string;
    password?: string;
    confirmPassword?: string;
  }>({});
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    // Validate all inputs
    const nameValidation = validateName(formData.name);
    const emailValidation = validateEmail(formData.email);
    const phoneValidation = validatePhone(formData.phone);
    const passwordValidation = validatePassword(formData.password);

    const newErrors: any = {};

    if (!nameValidation.valid) newErrors.name = nameValidation.error;
    if (!emailValidation.valid) newErrors.email = emailValidation.error;
    if (!phoneValidation.valid) newErrors.phone = phoneValidation.error;
    if (!passwordValidation.valid) newErrors.password = passwordValidation.error;

    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setErrors({});
    setLoading(true);

    try {
      // Format phone number to international format if needed
      let phone = formData.phone;
      if (phone.startsWith('0')) {
        phone = '+233' + phone.substring(1);
      }

      await registerUser({
        email: formData.email,
        password: formData.password,
        name: formData.name,
        phone,
      });

      Alert.alert(
        'Registration Successful',
        'Please check your email for a verification code.',
        [
          {
            text: 'OK',
            onPress: () => navigation.navigate('VerifyEmail', { email: formData.email }),
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('Registration Failed', error.message);
    } finally {
      setLoading(false);
    }
  };

  const updateField = (field: string, value: string) => {
    setFormData({ ...formData, [field]: value });
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.logo}>⚡ EcoVolt</Text>
          <Text style={styles.subtitle}>Join the Green Revolution</Text>
        </View>

        <View style={styles.form}>
          <Text style={styles.title}>Create Account</Text>

          <Input
            label="Full Name"
            value={formData.name}
            onChangeText={(value) => updateField('name', value)}
            placeholder="Enter your full name"
            autoCapitalize="words"
            error={errors.name}
          />

          <Input
            label="Email"
            value={formData.email}
            onChangeText={(value) => updateField('email', value)}
            placeholder="Enter your email"
            keyboardType="email-address"
            error={errors.email}
          />

          <Input
            label="Phone Number"
            value={formData.phone}
            onChangeText={(value) => updateField('phone', value)}
            placeholder="0XXXXXXXXX or +233XXXXXXXXX"
            keyboardType="phone-pad"
            error={errors.phone}
          />

          <Input
            label="Password"
            value={formData.password}
            onChangeText={(value) => updateField('password', value)}
            placeholder="Enter your password"
            secureTextEntry
            error={errors.password}
          />

          <Input
            label="Confirm Password"
            value={formData.confirmPassword}
            onChangeText={(value) => updateField('confirmPassword', value)}
            placeholder="Confirm your password"
            secureTextEntry
            error={errors.confirmPassword}
          />

          <Text style={styles.passwordHint}>
            Password must be at least 8 characters with uppercase, lowercase, number, and special character
          </Text>

          <Button title="Sign Up" onPress={handleRegister} loading={loading} />

          <View style={styles.footer}>
            <Text style={styles.footerText}>Already have an account? </Text>
            <TouchableOpacity onPress={() => navigation.navigate('Login')}>
              <Text style={styles.linkText}>Login</Text>
            </TouchableOpacity>
          </View>
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
  logo: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#2ecc71',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
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
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 24,
    textAlign: 'center',
  },
  passwordHint: {
    fontSize: 12,
    color: '#666',
    marginBottom: 16,
    fontStyle: 'italic',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 24,
  },
  footerText: {
    color: '#666',
    fontSize: 14,
  },
  linkText: {
    color: '#2ecc71',
    fontSize: 14,
    fontWeight: '600',
  },
});
