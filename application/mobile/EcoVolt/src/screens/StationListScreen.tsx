/**
 * Station List Screen
 * Shows nearby stations in a list view sorted by distance
 * Requirements: 2.1, 2.2
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Platform,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import {
  fetchStationsStart,
  fetchStationsSuccess,
  fetchStationsFailure,
  selectStation,
} from '../store/slices/stationsSlice';
import { getNearbyStations } from '../services/stationService';
import { Station } from '../types/station';

export default function StationListScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { nearby, loading, userLocation } = useSelector(
    (state: RootState) => state.stations
  );

  const handleRefresh = async () => {
    if (!userLocation) return;

    dispatch(fetchStationsStart());

    try {
      const stations = await getNearbyStations({
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
        radius: 10,
      });

      dispatch(fetchStationsSuccess(stations));
    } catch (error: any) {
      dispatch(fetchStationsFailure(error.message));
    }
  };

  const handleStationPress = (station: Station) => {
    dispatch(selectStation(station));
    navigation.navigate('StationDetails', { stationId: station.id });
  };

  const getStatusColor = (station: Station) => {
    if (station.status !== 'active') return '#95a5a6';
    if (station.availableBatteries === 0) return '#e74c3c';
    if (station.availableBatteries < 3) return '#f39c12';
    return '#2ecc71';
  };

  const getStatusText = (station: Station) => {
    if (station.status !== 'active') return 'Closed';
    if (station.availableBatteries === 0) return 'No Batteries';
    if (station.availableBatteries < 3) return 'Low Stock';
    return 'Available';
  };

  const renderStation = ({ item }: { item: Station }) => (
    <TouchableOpacity
      style={styles.stationCard}
      onPress={() => handleStationPress(item)}
    >
      <View style={styles.stationHeader}>
        <View style={styles.stationInfo}>
          <Text style={styles.stationName}>{item.name}</Text>
          <Text style={styles.stationAddress}>{item.address}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: getStatusColor(item) }]}>
          <Text style={styles.statusText}>{getStatusText(item)}</Text>
        </View>
      </View>

      <View style={styles.stationDetails}>
        <View style={styles.detailItem}>
          <Text style={styles.detailLabel}>Distance</Text>
          <Text style={styles.detailValue}>
            {item.distance ? `${item.distance.toFixed(1)} km` : 'N/A'}
          </Text>
        </View>

        <View style={styles.detailItem}>
          <Text style={styles.detailLabel}>Batteries</Text>
          <Text style={styles.detailValue}>
            {item.availableBatteries}/{item.totalCapacity}
          </Text>
        </View>

        <View style={styles.detailItem}>
          <Text style={styles.detailLabel}>Cost</Text>
          <Text style={styles.detailValue}>GHS {item.swapCost}</Text>
        </View>
      </View>

      <View style={styles.stationFooter}>
        <Text style={styles.operatingHours}>🕐 {item.operatingHours}</Text>
        <Text style={styles.viewDetails}>View Details →</Text>
      </View>
    </TouchableOpacity>
  );

  const renderEmpty = () => (
    <View style={styles.emptyContainer}>
      <Text style={styles.emptyIcon}>📍</Text>
      <Text style={styles.emptyTitle}>No Stations Found</Text>
      <Text style={styles.emptyText}>
        There are no stations within 10km of your location.
      </Text>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Nearby Stations</Text>
        <View style={{ width: 60 }} />
      </View>

      {/* Station List */}
      <FlatList
        data={nearby}
        renderItem={renderStation}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={handleRefresh} />
        }
        ListEmptyComponent={renderEmpty}
      />
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
  listContent: {
    padding: 16,
  },
  stationCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  stationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  stationInfo: {
    flex: 1,
  },
  stationName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  stationAddress: {
    fontSize: 14,
    color: '#666',
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
  stationDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#f0f0f0',
  },
  detailItem: {
    alignItems: 'center',
  },
  detailLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  detailValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  stationFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
  },
  operatingHours: {
    fontSize: 14,
    color: '#666',
  },
  viewDetails: {
    fontSize: 14,
    color: '#2ecc71',
    fontWeight: '600',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyIcon: {
    fontSize: 64,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    paddingHorizontal: 40,
  },
});
