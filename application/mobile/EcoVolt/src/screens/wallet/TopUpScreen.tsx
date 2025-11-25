/**
 * Top Up Screen
 * Requirements: 6.1, 6.2, 6.3, 6.6
 * Allows users to top up their wallet via Mobile Money
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Platform,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../../store';
import {
  topUpStart,
  topUpSuccess,
  topUpFailure,
  fetchBalanceSuccess,
} from '../../store/slices/walletSlice';
import { initiateTopUp } from '../../services/walletService';
import { validatePhone } from '../../utils/validation';
import Input from '../../components/Input';
import Button from '../../components/Button';

export default function TopUpScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { loading, currency } = useSelector((state: RootState) => state.wallet);

  const [amount, setAmount] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<
    'mtn_momo' | 'vodafone_cash' | 'airteltigo_money'
  >('mtn_momo');
  const [errors, setErrors] = useState<{ amount?: string; phoneNumber?: string }>({});

  const quickAmounts = [10, 20, 50, 100, 200, 500];

  const handleQuickAmount = (value: number) => {
    setAmount(value.toString());
    setErrors({ ...errors, amount: undefined });
  };

  const validateInputs = () => {
    const newErrors: any = {};

    // Validate amount
    const amountNum = parseFloat(amount);
    if (!amount || isNaN(amountNum)) {
      newErrors.amount = 'Amount is required';
    } else if (amountNum < 10) {
      newErrors.amount = 'Minimum top-up is GHS 10';
    } else if (amountNum > 1000) {
      newErrors.amount = 'Maximum top-up is GHS 1000';
    }

    // Validate phone number
    const phoneValidation = validatePhone(phoneNumber);
    if (!phoneValidation.valid) {
      newErrors.phoneNumber = phoneValidation.error;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleTopUp = async () => {
    if (!validateInputs()) {
      return;
    }

    dispatch(topUpStart());

    try {
      const response = await initiateTopUp({
        amount: parseFloat(amount),
        paymentMethod,
        phoneNumber,
      });

      dispatch(topUpSuccess(response.transaction));

      Alert.alert('Top-Up Initiated', response.message, [
        {
          text: 'OK',
          onPress: () => {
            // Update balance optimistically
            dispatch(
              fetchBalanceSuccess({
                balance: response.transaction.balanceAfter,
                currency: 'GHS',
              })
            );
            navigation.goBack();
          },
        },
      ]);
    } catch (error: any) {
      dispatch(topUpFailure(error.message));
      Alert.alert('Top-Up Failed', error.message);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Top Up Wallet</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView style={styles.content}>
        {/* Amount Input */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Enter Amount</Text>

          <Input
            label={`Amount (${currency})`}
            value={amount}
            onChangeText={setAmount}
            placeholder="Enter amount"
            keyboardType="numeric"
            error={errors.amount}
          />

          {/* Quick Amount Buttons */}
          <View style={styles.quickAmounts}>
            {quickAmounts.map((value) => (
              <TouchableOpacity
                key={value}
                style={[
                  styles.quickAmountButton,
                  amount === value.toString() && styles.quickAmountButtonActive,
                ]}
                onPress={() => handleQuickAmount(value)}
              >
                <Text
                  style={[
                    styles.quickAmountText,
                    amount === value.toString() && styles.quickAmountTextActive,
                  ]}
                >
                  {value}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={styles.limitText}>Min: GHS 10 • Max: GHS 1000</Text>
        </View>

        {/* Payment Method */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Payment Method</Text>

          <TouchableOpacity
            style={[
              styles.paymentOption,
              paymentMethod === 'mtn_momo' && styles.paymentOptionActive,
            ]}
            onPress={() => setPaymentMethod('mtn_momo')}
          >
            <View style={styles.paymentInfo}>
              <Text style={styles.paymentIcon}>📱</Text>
              <Text style={styles.paymentName}>MTN Mobile Money</Text>
            </View>
            {paymentMethod === 'mtn_momo' && (
              <Text style={styles.checkmark}>✓</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.paymentOption,
              paymentMethod === 'vodafone_cash' && styles.paymentOptionActive,
            ]}
            onPress={() => setPaymentMethod('vodafone_cash')}
          >
            <View style={styles.paymentInfo}>
              <Text style={styles.paymentIcon}>📱</Text>
              <Text style={styles.paymentName}>Vodafone Cash</Text>
            </View>
            {paymentMethod === 'vodafone_cash' && (
              <Text style={styles.checkmark}>✓</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.paymentOption,
              paymentMethod === 'airteltigo_money' && styles.paymentOptionActive,
            ]}
            onPress={() => setPaymentMethod('airteltigo_money')}
          >
            <View style={styles.paymentInfo}>
              <Text style={styles.paymentIcon}>📱</Text>
              <Text style={styles.paymentName}>AirtelTigo Money</Text>
            </View>
            {paymentMethod === 'airteltigo_money' && (
              <Text style={styles.checkmark}>✓</Text>
            )}
          </TouchableOpacity>
        </View>

        {/* Phone Number */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Mobile Money Number</Text>

          <Input
            label="Phone Number"
            value={phoneNumber}
            onChangeText={setPhoneNumber}
            placeholder="0XXXXXXXXX or +233XXXXXXXXX"
            keyboardType="phone-pad"
            error={errors.phoneNumber}
          />

          <Text style={styles.infoText}>
            Enter the phone number registered with your Mobile Money account
          </Text>
        </View>

        {/* Instructions */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>How it works</Text>
          <View style={styles.instructionItem}>
            <Text style={styles.instructionNumber}>1</Text>
            <Text style={styles.instructionText}>
              Enter the amount you want to add to your wallet
            </Text>
          </View>
          <View style={styles.instructionItem}>
            <Text style={styles.instructionNumber}>2</Text>
            <Text style={styles.instructionText}>
              Select your Mobile Money provider
            </Text>
          </View>
          <View style={styles.instructionItem}>
            <Text style={styles.instructionNumber}>3</Text>
            <Text style={styles.instructionText}>
              You'll receive a prompt on your phone to approve the payment
            </Text>
          </View>
          <View style={styles.instructionItem}>
            <Text style={styles.instructionNumber}>4</Text>
            <Text style={styles.instructionText}>
              Once approved, your wallet will be credited instantly
            </Text>
          </View>
        </View>
      </ScrollView>

      {/* Action Button */}
      <View style={styles.actions}>
        <Button
          title={`Top Up ${amount ? `GHS ${amount}` : 'Wallet'}`}
          onPress={handleTopUp}
          loading={loading}
          disabled={!amount || !phoneNumber}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: Platform.OS === 'ios' ? 50 : 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  backButton: {
    fontSize: 16,
    color: '#2ecc71',
    fontWeight: '600',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  content: {
    flex: 1,
  },
  card: {
    backgroundColor: '#fff',
    margin: 16,
    marginBottom: 0,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  quickAmounts: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
  },
  quickAmountButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    marginRight: 8,
    marginBottom: 8,
  },
  quickAmountButtonActive: {
    backgroundColor: '#2ecc71',
    borderColor: '#2ecc71',
  },
  quickAmountText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
  },
  quickAmountTextActive: {
    color: '#fff',
  },
  limitText: {
    fontSize: 12,
    color: '#999',
    marginTop: 8,
    textAlign: 'center',
  },
  paymentOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    marginBottom: 12,
  },
  paymentOptionActive: {
    borderColor: '#2ecc71',
    backgroundColor: '#f0fdf4',
  },
  paymentInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  paymentIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  paymentName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  checkmark: {
    fontSize: 20,
    color: '#2ecc71',
  },
  infoText: {
    fontSize: 12,
    color: '#666',
    marginTop: 8,
    fontStyle: 'italic',
  },
  instructionItem: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  instructionNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#2ecc71',
    color: '#fff',
    textAlign: 'center',
    lineHeight: 24,
    fontWeight: 'bold',
    marginRight: 12,
  },
  instructionText: {
    flex: 1,
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
  actions: {
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
});
