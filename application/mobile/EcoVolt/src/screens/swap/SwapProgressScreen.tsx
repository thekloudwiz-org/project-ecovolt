/**
 * Swap Progress Screen
 * Requirements: 4.1, 4.2, 4.3
 * Shows swap progress and allows completion
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../../store';
import {
  completeSwapStart,
  completeSwapSuccess,
  completeSwapFailure,
  clearCurrentSwap,
} from '../../store/slices/swapsSlice';
import { completeSwap, getSwapStatus } from '../../services/swapService';
import Button from '../../components/Button';

export default function SwapProgressScreen({ route, navigation }: any) {
  const { swapId, reservedBatteryId } = route.params;
  const dispatch = useDispatch();
  const { current, loading } = useSelector((state: RootState) => state.swaps);

  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (!current) {
      fetchSwapStatus();
    }
  }, []);

  const fetchSwapStatus = async () => {
    setRefreshing(true);
    try {
      const swap = await getSwapStatus(swapId);
      dispatch(completeSwapSuccess(swap));
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setRefreshing(false);
    }
  };

  const handleCompleteSwap = async () => {
    Alert.alert(
      'Complete Swap',
      'Have you physically swapped the battery at the station?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Complete',
          onPress: async () => {
            dispatch(completeSwapStart());

            try {
              const response = await completeSwap({ swapId });
              dispatch(completeSwapSuccess(response.swap));

              Alert.alert('Swap Completed', response.message, [
                {
                  text: 'OK',
                  onPress: () => navigation.navigate('SwapSuccess', { swap: response.swap }),
                },
              ]);
            } catch (error: any) {
              dispatch(completeSwapFailure(error.message));
              Alert.alert('Completion Failed', error.message);
            }
          },
        },
      ]
    );
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancel Swap',
      'Are you sure you want to cancel this swap? The cost will not be refunded.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Yes, Cancel',
          style: 'destructive',
          onPress: () => {
            dispatch(clearCurrentSwap());
            navigation.navigate('Home');
          },
        },
      ]
    );
  };

  if (!current && refreshing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2ecc71" />
      </View>
    );
  }

  if (!current) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Swap not found</Text>
      </View>
    );
  }

  const isCompleted = current.status === 'completed';

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.navigate('Home')}>
          <Text style={styles.backButton}>← Home</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Swap Progress</Text>
        <TouchableOpacity onPress={fetchSwapStatus}>
          <Text style={styles.refreshButton}>↻</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content}>
        {/* Status Card */}
        <View style={styles.statusCard}>
          <Text style={styles.statusIcon}>
            {isCompleted ? '✅' : '⏳'}
          </Text>
          <Text style={styles.statusTitle}>
            {isCompleted ? 'Swap Completed' : 'Swap In Progress'}
          </Text>
          <Text style={styles.statusSubtitle}>
            {isCompleted
              ? 'Your battery has been successfully swapped'
              : 'Please complete the physical swap at the station'}
          </Text>
        </View>

        {/* Swap Details */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Swap Details</Text>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Swap ID</Text>
            <Text style={styles.detailValue}>{current.id}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Station</Text>
            <Text style={styles.detailValue}>{current.stationName || 'N/A'}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Bike ID</Text>
            <Text style={styles.detailValue}>{current.bikeId}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Reserved Battery</Text>
            <Text style={styles.detailValue}>{reservedBatteryId}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Cost</Text>
            <Text style={styles.detailValue}>GHS {current.cost}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Status</Text>
            <View
              style={[
                styles.statusBadge,
                {
                  backgroundColor: isCompleted ? '#2ecc71' : '#f39c12',
                },
              ]}
            >
              <Text style={styles.statusBadgeText}>
                {current.status.toUpperCase()}
              </Text>
            </View>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Initiated At</Text>
            <Text style={styles.detailValue}>
              {new Date(current.initiatedAt).toLocaleString()}
            </Text>
          </View>

          {isCompleted && current.completedAt && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Completed At</Text>
              <Text style={styles.detailValue}>
                {new Date(current.completedAt).toLocaleString()}
              </Text>
            </View>
          )}
        </View>

        {/* Instructions */}
        {!isCompleted && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Next Steps</Text>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>1</Text>
              <Text style={styles.instructionText}>
                Go to the station and locate the reserved battery
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>2</Text>
              <Text style={styles.instructionText}>
                Remove your depleted battery from the bike
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>3</Text>
              <Text style={styles.instructionText}>
                Insert the charged battery into your bike
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>4</Text>
              <Text style={styles.instructionText}>
                Return the depleted battery to the charging slot
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>5</Text>
              <Text style={styles.instructionText}>
                Tap "Complete Swap" below to finish
              </Text>
            </View>
          </View>
        )}
      </ScrollView>

      {/* Action Buttons */}
      <View style={styles.actions}>
        {!isCompleted ? (
          <>
            <TouchableOpacity
              style={[styles.actionButton, styles.cancelButton]}
              onPress={handleCancel}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <View style={{ width: 12 }} />
            <View style={{ flex: 1 }}>
              <Button
                title="Complete Swap"
                onPress={handleCompleteSwap}
                loading={loading}
              />
            </View>
          </>
        ) : (
          <Button
            title="Back to Home"
            onPress={() => {
              dispatch(clearCurrentSwap());
              navigation.navigate('Home');
            }}
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#666',
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
  refreshButton: {
    fontSize: 24,
    color: '#2ecc71',
  },
  content: {
    flex: 1,
  },
  statusCard: {
    backgroundColor: '#fff',
    margin: 16,
    padding: 24,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusIcon: {
    fontSize: 64,
    marginBottom: 16,
  },
  statusTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  statusSubtitle: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  card: {
    backgroundColor: '#fff',
    margin: 16,
    marginTop: 0,
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
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  detailLabel: {
    fontSize: 14,
    color: '#666',
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    textAlign: 'right',
    flex: 1,
    marginLeft: 16,
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  statusBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
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
    flexDirection: 'row',
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  actionButton: {
    flex: 1,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#e74c3c',
  },
  cancelButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
