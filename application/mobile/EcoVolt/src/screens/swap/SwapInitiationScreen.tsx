/**
 * Swap Initiation Screen
 * Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
 * Allows user to initiate a battery swap at a station
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
  initiateSwapStart,
  initiateSwapSuccess,
  initiateSwapFailure,
} from '../../store/slices/swapsSlice';
import { initiateSwap } from '../../services/swapService';
import { getStationDetails } from '../../services/stationService';
import Input from '../../components/Input';
import Button from '../../components/Button';

export default function SwapInitiationScreen({ route, navigation }: any) {
  const { stationId } = route.params;
  const dispatch = useDispatch();
  const { selected: station } = useSelector((state: RootState) => state.stations);
  const { loading } = useSelector((state: RootState) => state.swaps);

  const [bikeId, setBikeId] = useState('');
  const [bikeIdError, setBikeIdError] = useState('');
  const [stationDetails, setStationDetails] = useState<any>(null);
  const [loadingDetails, setLoadingDetails] = useState(true);

  useEffect(() => {
    fetchStationDetails();
  }, [stationId]);

  const fetchStationDetails = async () => {
    try {
      const details = await getStationDetails(stationId);
      setStationDetails(details);
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoadingDetails(false);
    }
  };

  const handleInitiateSwap = async () => {
    // Validate bike ID
    if (!bikeId.trim()) {
      setBikeIdError('Bike ID is required');
      return;
    }

    setBikeIdError('');
    dispatch(initiateSwapStart());

    try {
      const response = await initiateSwap({
        bikeId: bikeId.trim(),
        stationId,
      });

      dispatch(initiateSwapSuccess(response.swap));

      Alert.alert('Swap Initiated', response.message, [
        {
          text: 'Continue',
          onPress: () =>
            navigation.navigate('SwapProgress', {
              swapId: response.swap.id,
              reservedBatteryId: response.reservedBatteryId,
            }),
        },
      ]);
    } catch (error: any) {
      dispatch(initiateSwapFailure(error.message));
      Alert.alert('Swap Failed', error.message);
    }
  };

  const handleScanQR = () => {
    // In a real app, this would open a QR code scanner
    Alert.alert(
      'QR Scanner',
      'QR code scanning would open here. For demo, please enter bike ID manually.'
    );
  };

  if (loadingDetails) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2ecc71" />
      </View>
    );
  }

  if (!station || !stationDetails) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Station not found</Text>
      </View>
    );
  }

  const isAvailable =
    station.status === 'active' && stationDetails.realtimeBatteryCount > 0;

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Initiate Swap</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView style={styles.content}>
        {/* Station Info */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Station</Text>
          <Text style={styles.stationName}>{station.name}</Text>
          <Text style={styles.stationAddress}>{station.address}</Text>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Available Batteries</Text>
            <Text style={styles.infoValue}>
              {stationDetails.realtimeBatteryCount}
            </Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Swap Cost</Text>
            <Text style={styles.infoValue}>GHS {station.swapCost}</Text>
          </View>
        </View>

        {/* Availability Warning */}
        {!isAvailable && (
          <View style={styles.warningCard}>
            <Text style={styles.warningIcon}>⚠️</Text>
            <Text style={styles.warningText}>
              {station.status !== 'active'
                ? 'This station is currently closed'
                : 'No batteries available at this station'}
            </Text>
          </View>
        )}

        {/* Bike ID Input */}
        {isAvailable && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Bike Information</Text>

            <Input
              label="Bike ID"
              value={bikeId}
              onChangeText={setBikeId}
              placeholder="Enter your bike ID"
              error={bikeIdError}
              autoCapitalize="characters"
            />

            <TouchableOpacity style={styles.qrButton} onPress={handleScanQR}>
              <Text style={styles.qrButtonText}>📷 Scan QR Code</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Instructions */}
        {isAvailable && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Instructions</Text>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>1</Text>
              <Text style={styles.instructionText}>
                Enter your bike ID or scan the QR code on your bike
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>2</Text>
              <Text style={styles.instructionText}>
                Confirm the swap cost will be deducted from your wallet
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>3</Text>
              <Text style={styles.instructionText}>
                A battery will be reserved for you at the station
              </Text>
            </View>
            <View style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>4</Text>
              <Text style={styles.instructionText}>
                Complete the physical swap at the station
              </Text>
            </View>
          </View>
        )}
      </ScrollView>

      {/* Action Button */}
      {isAvailable && (
        <View style={styles.actions}>
          <Button
            title={`Initiate Swap - GHS ${station.swapCost}`}
            onPress={handleInitiateSwap}
            loading={loading}
          />
        </View>
      )}
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
    marginBottom: 12,
  },
  stationName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  stationAddress: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  warningCard: {
    backgroundColor: '#fff3cd',
    margin: 16,
    marginBottom: 0,
    padding: 16,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ffc107',
  },
  warningIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    color: '#856404',
  },
  qrButton: {
    backgroundColor: '#3498db',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  qrButtonText: {
    color: '#fff',
    fontSize: 16,
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
    padding: 16,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
});
