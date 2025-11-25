/**
 * Station Details Screen
 * Shows detailed information about a station
 * Requirements: 2.2, 2.4
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Platform,
  Linking,
} from 'react-native';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { getStationDetails } from '../services/stationService';
import { StationDetailsResponse } from '../types/station';

export default function StationDetailsScreen({ route, navigation }: any) {
  const { stationId } = route.params;
  const { selected } = useSelector((state: RootState) => state.stations);

  const [details, setDetails] = useState<StationDetailsResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDetails();
  }, [stationId]);

  const fetchDetails = async () => {
    setLoading(true);
    try {
      const data = await getStationDetails(stationId);
      setDetails(data);
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleNavigate = () => {
    if (!selected) return;

    const url = Platform.select({
      ios: `maps:0,0?q=${selected.latitude},${selected.longitude}`,
      android: `geo:0,0?q=${selected.latitude},${selected.longitude}(${selected.name})`,
    });

    if (url) {
      Linking.openURL(url).catch(() => {
        Alert.alert('Error', 'Unable to open maps');
      });
    }
  };

  const handleStartSwap = () => {
    if (!selected) return;

    if (selected.availableBatteries === 0) {
      Alert.alert('No Batteries Available', 'This station currently has no batteries available.');
      return;
    }

    navigation.navigate('SwapInitiation', { stationId: selected.id });
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2ecc71" />
      </View>
    );
  }

  if (!details || !selected) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Station not found</Text>
      </View>
    );
  }

  const station = details.station;
  const isAvailable = station.status === 'active' && station.availableBatteries > 0;

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Station Details</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView style={styles.content}>
        {/* Station Info */}
        <View style={styles.card}>
          <Text style={styles.stationName}>{station.name}</Text>
          <Text style={styles.stationAddress}>{station.address}</Text>
          <Text style={styles.stationCity}>{station.city}</Text>

          <View style={styles.statusContainer}>
            <View
              style={[
                styles.statusBadge,
                {
                  backgroundColor: isAvailable ? '#2ecc71' : '#e74c3c',
                },
              ]}
            >
              <Text style={styles.statusText}>
                {station.status === 'active' ? 'Open' : 'Closed'}
              </Text>
            </View>
          </View>
        </View>

        {/* Battery Availability */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Battery Availability</Text>
          <View style={styles.batteryInfo}>
            <View style={styles.batteryCount}>
              <Text style={styles.batteryNumber}>{details.realtimeBatteryCount}</Text>
              <Text style={styles.batteryLabel}>Available Now</Text>
            </View>
            <View style={styles.batteryCount}>
              <Text style={styles.batteryNumber}>{station.totalCapacity}</Text>
              <Text style={styles.batteryLabel}>Total Capacity</Text>
            </View>
          </View>

          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                {
                  width: `${(details.realtimeBatteryCount / station.totalCapacity) * 100}%`,
                },
              ]}
            />
          </View>
        </View>

        {/* Operating Info */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Operating Information</Text>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Operating Hours</Text>
            <Text style={styles.infoValue}>{station.operatingHours}</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Swap Cost</Text>
            <Text style={styles.infoValue}>GHS {station.swapCost}</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Distance</Text>
            <Text style={styles.infoValue}>
              {station.distance ? `${station.distance.toFixed(1)} km` : 'N/A'}
            </Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Recent Swaps (24h)</Text>
            <Text style={styles.infoValue}>{details.recentSwaps}</Text>
          </View>
        </View>

        {/* Location */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Location</Text>
          <Text style={styles.coordinates}>
            {station.latitude.toFixed(6)}, {station.longitude.toFixed(6)}
          </Text>
        </View>
      </ScrollView>

      {/* Action Buttons */}
      <View style={styles.actions}>
        <TouchableOpacity
          style={[styles.actionButton, styles.navigateButton]}
          onPress={handleNavigate}
        >
          <Text style={styles.actionButtonText}>🗺️ Navigate</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.actionButton,
            styles.swapButton,
            !isAvailable && styles.disabledButton,
          ]}
          onPress={handleStartSwap}
          disabled={!isAvailable}
        >
          <Text style={styles.actionButtonText}>
            {isAvailable ? '⚡ Start Swap' : '❌ Unavailable'}
          </Text>
        </TouchableOpacity>
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
  stationName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  stationAddress: {
    fontSize: 16,
    color: '#666',
    marginBottom: 4,
  },
  stationCity: {
    fontSize: 14,
    color: '#999',
  },
  statusContainer: {
    marginTop: 12,
  },
  statusBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 16,
  },
  statusText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  batteryInfo: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 16,
  },
  batteryCount: {
    alignItems: 'center',
  },
  batteryNumber: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#2ecc71',
  },
  batteryLabel: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#2ecc71',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
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
  coordinates: {
    fontSize: 14,
    color: '#666',
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
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
    marginHorizontal: 4,
  },
  navigateButton: {
    backgroundColor: '#3498db',
  },
  swapButton: {
    backgroundColor: '#2ecc71',
  },
  disabledButton: {
    backgroundColor: '#95a5a6',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
