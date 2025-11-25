/**
 * Swap Success Screen
 * Shows confirmation after successful swap completion
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Platform,
} from 'react-native';
import { useDispatch } from 'react-redux';
import { clearCurrentSwap } from '../../store/slices/swapsSlice';
import Button from '../../components/Button';

export default function SwapSuccessScreen({ route, navigation }: any) {
  const { swap } = route.params;
  const dispatch = useDispatch();

  const handleDone = () => {
    dispatch(clearCurrentSwap());
    navigation.navigate('Home');
  };

  const handleViewHistory = () => {
    dispatch(clearCurrentSwap());
    navigation.navigate('History');
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        {/* Success Icon */}
        <View style={styles.successCard}>
          <Text style={styles.successIcon}>🎉</Text>
          <Text style={styles.successTitle}>Swap Completed!</Text>
          <Text style={styles.successSubtitle}>
            Your battery has been successfully swapped
          </Text>
        </View>

        {/* Swap Summary */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Swap Summary</Text>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Swap ID</Text>
            <Text style={styles.summaryValue}>{swap.id}</Text>
          </View>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Station</Text>
            <Text style={styles.summaryValue}>{swap.stationName || 'N/A'}</Text>
          </View>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Cost</Text>
            <Text style={styles.summaryValue}>GHS {swap.cost}</Text>
          </View>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Duration</Text>
            <Text style={styles.summaryValue}>
              {swap.duration ? `${swap.duration} min` : 'N/A'}
            </Text>
          </View>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Completed At</Text>
            <Text style={styles.summaryValue}>
              {swap.completedAt
                ? new Date(swap.completedAt).toLocaleString()
                : 'N/A'}
            </Text>
          </View>
        </View>

        {/* Tips */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>💡 Tips</Text>
          <Text style={styles.tipText}>
            • Keep your battery charged above 20% for optimal performance
          </Text>
          <Text style={styles.tipText}>
            • Plan your swaps ahead using the station finder
          </Text>
          <Text style={styles.tipText}>
            • Top up your wallet to avoid delays during swaps
          </Text>
        </View>
      </ScrollView>

      {/* Action Buttons */}
      <View style={styles.actions}>
        <Button title="View History" onPress={handleViewHistory} variant="outline" />
        <View style={{ height: 12 }} />
        <Button title="Done" onPress={handleDone} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flexGrow: 1,
    padding: 16,
    paddingTop: Platform.OS === 'ios' ? 60 : 40,
  },
  successCard: {
    backgroundColor: '#fff',
    padding: 32,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  successIcon: {
    fontSize: 80,
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2ecc71',
    marginBottom: 8,
  },
  successSubtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  card: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
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
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  summaryLabel: {
    fontSize: 14,
    color: '#666',
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    textAlign: 'right',
    flex: 1,
    marginLeft: 16,
  },
  tipText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
    lineHeight: 20,
  },
  actions: {
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
});
