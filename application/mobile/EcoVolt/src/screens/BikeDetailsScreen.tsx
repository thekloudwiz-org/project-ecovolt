/**
 * Bike Details Screen
 * Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
 * Shows detailed bike information and telemetry
 */

import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Platform,
  RefreshControl,
  Alert,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import {
  fetchBikeStart,
  fetchBikeSuccess,
  fetchBikeFailure,
} from '../store/slices/bikeSlice';
import { getBikeDetails } from '../services/bikeService';

export default function BikeDetailsScreen({ route, navigation }: any) {
  const { bikeId } = route.params;
  const dispatch = useDispatch();
  const { details: bike, telemetry, loading } = useSelector(
    (state: RootState) => state.bike
  );

  useEffect(() => {
    fetchBike();
  }, [bikeId]);

  const fetchBike = async () => {
    dispatch(fetchBikeStart());
    try {
      const data = await getBikeDetails(bikeId);
      dispatch(
        fetchBikeSuccess({
          bike: data.bike,
          telemetry: data.telemetry,
        })
      );
    } catch (error: any) {
      dispatch(fetchBikeFailure(error.message));
      Alert.alert('Error', error.message);
    }
  };

  const getBatteryColor = (level: number) => {
    if (level > 60) return '#2ecc71';
    if (level > 20) return '#f39c12';
    return '#e74c3c';
  };

  if (!bike) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <Text style={styles.backButton}>← Back</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Bike Details</Text>
          <View style={{ width: 60 }} />
        </View>
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>Bike not found</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Bike Details</Text>
        <TouchableOpacity onPress={fetchBike}>
          <Text style={styles.refreshButton}>↻</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={fetchBike} />}
      >
        {/* Bike Info Card */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>🏍️ Bike Information</Text>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Bike ID</Text>
            <Text style={styles.infoValue}>{bike.id}</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Model</Text>
            <Text style={styles.infoValue}>{bike.model}</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Status</Text>
            <View
              style={[
                styles.statusBadge,
                {
                  backgroundColor:
                    bike.status === 'active' ? '#2ecc71' : '#95a5a6',
                },
              ]}
            >
              <Text style={styles.statusText}>{bike.status.toUpperCase()}</Text>
            </View>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Battery ID</Text>
            <Text style={styles.infoValue}>{bike.batteryId}</Text>
          </View>

          {bike.lastSwapAt && (
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Last Swap</Text>
              <Text style={styles.infoValue}>
                {new Date(bike.lastSwapAt).toLocaleString()}
              </Text>
            </View>
          )}
        </View>

        {/* Battery Status */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>🔋 Battery Status</Text>
            {telemetry?.isStale && (
              <Text style={styles.staleIndicator}>⚠️ Outdated</Text>
            )}
          </View>

          <View style={styles.batteryDisplay}>
            <Text
              style={[
                styles.batteryLevel,
                {
                  color: getBatteryColor(
                    telemetry?.batteryLevel || bike.batteryLevel
                  ),
                },
              ]}
            >
              {telemetry?.batteryLevel || bike.batteryLevel}%
            </Text>
          </View>

          <View style={styles.batteryBar}>
            <View
              style={[
                styles.batteryFill,
                {
                  width: `${telemetry?.batteryLevel || bike.batteryLevel}%`,
                  backgroundColor: getBatteryColor(
                    telemetry?.batteryLevel || bike.batteryLevel
                  ),
                },
              ]}
            />
          </View>

          {telemetry && (
            <Text style={styles.telemetryTime}>
              Last updated: {new Date(telemetry.timestamp).toLocaleString()}
            </Text>
          )}
        </View>

        {/* Telemetry Data */}
        {telemetry && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>📊 Real-Time Telemetry</Text>

            <View style={styles.telemetryGrid}>
              <View style={styles.telemetryItem}>
                <Text style={styles.telemetryLabel}>Speed</Text>
                <Text style={styles.telemetryValue}>{telemetry.speed} km/h</Text>
              </View>

              <View style={styles.telemetryItem}>
                <Text style={styles.telemetryLabel}>Odometer</Text>
                <Text style={styles.telemetryValue}>
                  {telemetry.odometer.toFixed(1)} km
                </Text>
              </View>

              <View style={styles.telemetryItem}>
                <Text style={styles.telemetryLabel}>Temperature</Text>
                <Text style={styles.telemetryValue}>{telemetry.temperature}°C</Text>
              </View>

              <View style={styles.telemetryItem}>
                <Text style={styles.telemetryLabel}>Location</Text>
                <Text style={styles.telemetryValue}>
                  {telemetry.latitude.toFixed(4)}, {telemetry.longitude.toFixed(4)}
                </Text>
              </View>
            </View>
          </View>
        )}

        {/* Location */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📍 Location</Text>
          <Text style={styles.coordinates}>
            Lat: {(telemetry?.latitude || bike.latitude).toFixed(6)}
          </Text>
          <Text style={styles.coordinates}>
            Lng: {(telemetry?.longitude || bike.longitude).toFixed(6)}
          </Text>
        </View>
      </ScrollView>
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
  refreshButton: {
    fontSize: 24,
    color: '#2ecc71',
  },
  content: {
    flex: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
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
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
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
    textAlign: 'right',
    flex: 1,
    marginLeft: 16,
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  staleIndicator: {
    fontSize: 12,
    color: '#f39c12',
    fontWeight: '600',
  },
  batteryDisplay: {
    alignItems: 'center',
    marginBottom: 16,
  },
  batteryLevel: {
    fontSize: 48,
    fontWeight: 'bold',
  },
  batteryBar: {
    height: 12,
    backgroundColor: '#e0e0e0',
    borderRadius: 6,
    overflow: 'hidden',
    marginBottom: 8,
  },
  batteryFill: {
    height: '100%',
  },
  telemetryTime: {
    fontSize: 12,
    color: '#999',
    textAlign: 'center',
  },
  telemetryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  telemetryItem: {
    width: '50%',
    paddingVertical: 12,
  },
  telemetryLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  telemetryValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  coordinates: {
    fontSize: 14,
    color: '#666',
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
    marginBottom: 4,
  },
});
