/**
 * Home Screen
 * Main dashboard showing bike status and quick actions
 * Requirements: 7.1, 7.2, 7.3, 7.4
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  RefreshControl,
  Alert,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import { logout } from '../store/slices/authSlice';
import {
  fetchBikeStart,
  fetchBikeSuccess,
  fetchBikeFailure,
} from '../store/slices/bikeSlice';
import { getBikeDetails } from '../services/bikeService';

export default function HomeScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { user } = useSelector((state: RootState) => state.auth);
  const { details: bike, telemetry, loading } = useSelector(
    (state: RootState) => state.bike
  );

  // For demo purposes, using a hardcoded bike ID
  // In production, this would come from user profile
  const [bikeId] = useState('BIKE001');

  useEffect(() => {
    fetchBike();
  }, []);

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
      // Don't show alert for demo - bike might not exist
    }
  };

  const handleLogout = () => {
    dispatch(logout());
  };

  const getBatteryColor = (level: number) => {
    if (level > 60) return '#2ecc71';
    if (level > 20) return '#f39c12';
    return '#e74c3c';
  };

  const getBatteryIcon = (level: number) => {
    if (level > 75) return '🔋';
    if (level > 50) return '🔋';
    if (level > 25) return '🪫';
    return '🪫';
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.logo}>⚡ EcoVolt</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity
            style={styles.notificationButton}
            onPress={() => navigation.navigate('Notifications')}
          >
            <Text style={styles.notificationIcon}>🔔</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={handleLogout}>
            <Text style={styles.logoutButton}>Logout</Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={fetchBike} />}
      >
        {/* Welcome Section */}
        <View style={styles.welcomeCard}>
          <Text style={styles.welcomeTitle}>Welcome back{user?.name ? `, ${user.name}` : ''}!</Text>
          <Text style={styles.welcomeText}>
            {bike
              ? 'Your bike is ready to ride'
              : 'Find nearby stations and swap your battery in minutes'}
          </Text>
        </View>

        {/* Bike Status Card */}
        {bike && (
          <View style={styles.bikeCard}>
            <View style={styles.bikeHeader}>
              <Text style={styles.bikeTitle}>🏍️ My Bike</Text>
              <TouchableOpacity onPress={() => navigation.navigate('BikeDetails', { bikeId })}>
                <Text style={styles.viewDetailsText}>Details →</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.bikeInfo}>
              <Text style={styles.bikeModel}>{bike.model}</Text>
              <Text style={styles.bikeId}>ID: {bike.id}</Text>
            </View>

            {/* Battery Level */}
            <View style={styles.batterySection}>
              <View style={styles.batteryHeader}>
                <Text style={styles.batteryLabel}>Battery Level</Text>
                {telemetry?.isStale && (
                  <Text style={styles.staleIndicator}>⚠️ Data may be outdated</Text>
                )}
              </View>

              <View style={styles.batteryDisplay}>
                <Text style={styles.batteryIcon}>
                  {getBatteryIcon(telemetry?.batteryLevel || bike.batteryLevel)}
                </Text>
                <Text
                  style={[
                    styles.batteryLevel,
                    { color: getBatteryColor(telemetry?.batteryLevel || bike.batteryLevel) },
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
            </View>

            {/* Quick Stats */}
            <View style={styles.quickStats}>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Odometer</Text>
                <Text style={styles.statValue}>
                  {(telemetry?.odometer || bike.odometer).toFixed(1)} km
                </Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Status</Text>
                <Text style={styles.statValue}>{bike.status}</Text>
              </View>
              {telemetry && (
                <View style={styles.statItem}>
                  <Text style={styles.statLabel}>Speed</Text>
                  <Text style={styles.statValue}>{telemetry.speed} km/h</Text>
                </View>
              )}
            </View>
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.actionCard}
            onPress={() => navigation.navigate('StationMap')}
          >
            <Text style={styles.actionIcon}>🗺️</Text>
            <Text style={styles.actionTitle}>Find Stations</Text>
            <Text style={styles.actionDescription}>Locate nearby swap stations</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionCard}
            onPress={() => navigation.navigate('Wallet')}
          >
            <Text style={styles.actionIcon}>💰</Text>
            <Text style={styles.actionTitle}>My Wallet</Text>
            <Text style={styles.actionDescription}>Manage your balance</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionCard}
            onPress={() => navigation.navigate('History')}
          >
            <Text style={styles.actionIcon}>📜</Text>
            <Text style={styles.actionTitle}>Swap History</Text>
            <Text style={styles.actionDescription}>View past swaps</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionCard}
            onPress={() => navigation.navigate('Profile')}
          >
            <Text style={styles.actionIcon}>👤</Text>
            <Text style={styles.actionTitle}>Profile</Text>
            <Text style={styles.actionDescription}>Manage your account</Text>
          </TouchableOpacity>
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
    paddingTop: 50,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  logo: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2ecc71',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  notificationButton: {
    marginRight: 16,
  },
  notificationIcon: {
    fontSize: 24,
  },
  logoutButton: {
    fontSize: 14,
    color: '#e74c3c',
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  welcomeCard: {
    backgroundColor: '#2ecc71',
    margin: 16,
    padding: 24,
    borderRadius: 12,
  },
  welcomeTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  welcomeText: {
    fontSize: 16,
    color: '#fff',
    opacity: 0.9,
  },
  actionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: 8,
  },
  actionCard: {
    width: '47%',
    backgroundColor: '#fff',
    margin: 8,
    padding: 20,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  actionIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  actionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  actionDescription: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
  },
});
