/**
 * Station Map Screen
 * Requirements: 2.1, 2.2, 2.4
 * Shows nearby stations on a map with real-time availability
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import MapView, { Marker, PROVIDER_GOOGLE, Region } from 'react-native-maps';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import {
  fetchStationsStart,
  fetchStationsSuccess,
  fetchStationsFailure,
  selectStation,
  setUserLocation,
} from '../store/slices/stationsSlice';
import { getNearbyStations } from '../services/stationService';
import { Station } from '../types/station';

export default function StationMapScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { nearby, loading, userLocation } = useSelector(
    (state: RootState) => state.stations
  );

  const [region, setRegion] = useState<Region>({
    latitude: 5.6037, // Accra, Ghana
    longitude: -0.187,
    latitudeDelta: 0.0922,
    longitudeDelta: 0.0421,
  });

  const [locationPermission, setLocationPermission] = useState(false);

  useEffect(() => {
    requestLocationPermission();
  }, []);

  useEffect(() => {
    if (userLocation) {
      fetchNearbyStations();
    }
  }, [userLocation]);

  const requestLocationPermission = async () => {
    try {
      // In a real app, use expo-location or react-native-permissions
      // For now, we'll use a default location (Accra)
      const defaultLocation = {
        latitude: 5.6037,
        longitude: -0.187,
      };

      dispatch(setUserLocation(defaultLocation));
      setRegion({
        ...region,
        latitude: defaultLocation.latitude,
        longitude: defaultLocation.longitude,
      });
      setLocationPermission(true);
    } catch (error) {
      Alert.alert('Location Error', 'Unable to get your location');
    }
  };

  const fetchNearbyStations = async () => {
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
      Alert.alert('Error', error.message);
    }
  };

  const handleMarkerPress = (station: Station) => {
    dispatch(selectStation(station));
    navigation.navigate('StationDetails', { stationId: station.id });
  };

  const handleRefresh = () => {
    fetchNearbyStations();
  };

  const getMarkerColor = (station: Station) => {
    if (station.status !== 'active') return '#95a5a6';
    if (station.availableBatteries === 0) return '#e74c3c';
    if (station.availableBatteries < 3) return '#f39c12';
    return '#2ecc71';
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Find Stations</Text>
        <TouchableOpacity onPress={handleRefresh} disabled={loading}>
          <Text style={styles.refreshButton}>
            {loading ? '⟳' : '↻'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Map */}
      <MapView
        provider={PROVIDER_GOOGLE}
        style={styles.map}
        region={region}
        onRegionChangeComplete={setRegion}
        showsUserLocation={locationPermission}
        showsMyLocationButton={true}
      >
        {nearby.map((station) => (
          <Marker
            key={station.id}
            coordinate={{
              latitude: station.latitude,
              longitude: station.longitude,
            }}
            title={station.name}
            description={`${station.availableBatteries} batteries available`}
            pinColor={getMarkerColor(station)}
            onPress={() => handleMarkerPress(station)}
          />
        ))}
      </MapView>

      {/* Station Count */}
      <View style={styles.stationCount}>
        <Text style={styles.stationCountText}>
          {nearby.length} station{nearby.length !== 1 ? 's' : ''} nearby
        </Text>
      </View>

      {/* Loading Indicator */}
      {loading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#2ecc71" />
        </View>
      )}

      {/* Legend */}
      <View style={styles.legend}>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: '#2ecc71' }]} />
          <Text style={styles.legendText}>Available</Text>
        </View>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: '#f39c12' }]} />
          <Text style={styles.legendText}>Low Stock</Text>
        </View>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: '#e74c3c' }]} />
          <Text style={styles.legendText}>Empty</Text>
        </View>
      </View>

      {/* List View Button */}
      <TouchableOpacity
        style={styles.listButton}
        onPress={() => navigation.navigate('StationList')}
      >
        <Text style={styles.listButtonText}>📋 List View</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  refreshButton: {
    fontSize: 24,
    color: '#2ecc71',
  },
  map: {
    flex: 1,
  },
  stationCount: {
    position: 'absolute',
    top: Platform.OS === 'ios' ? 100 : 70,
    left: 16,
    backgroundColor: '#fff',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  stationCountText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  legend: {
    position: 'absolute',
    bottom: 80,
    left: 16,
    backgroundColor: '#fff',
    padding: 12,
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 4,
  },
  legendDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 8,
  },
  legendText: {
    fontSize: 12,
    color: '#666',
  },
  listButton: {
    position: 'absolute',
    bottom: 16,
    right: 16,
    backgroundColor: '#2ecc71',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 25,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
  listButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
