/**
 * History Screen
 * Requirements: 5.1, 5.2, 5.3, 5.4
 * Shows swap history with pagination
 */

import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Platform,
  RefreshControl,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import {
  fetchHistoryStart,
  fetchHistorySuccess,
  fetchHistoryFailure,
} from '../store/slices/swapsSlice';
import { getSwapHistory } from '../services/swapService';
import { Swap } from '../types/swap';

export default function HistoryScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { history, loading, historyPage, historyTotal } = useSelector(
    (state: RootState) => state.swaps
  );

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async (page = 1) => {
    dispatch(fetchHistoryStart());
    try {
      const data = await getSwapHistory({ page, pageSize: 20 });
      dispatch(
        fetchHistorySuccess({
          swaps: data.swaps,
          total: data.total,
          page: data.page,
        })
      );
    } catch (error: any) {
      dispatch(fetchHistoryFailure(error.message));
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return '#2ecc71';
      case 'initiated':
        return '#f39c12';
      case 'failed':
        return '#e74c3c';
      case 'cancelled':
        return '#95a5a6';
      default:
        return '#666';
    }
  };

  const renderSwap = ({ item }: { item: Swap }) => (
    <TouchableOpacity
      style={styles.swapCard}
      onPress={() => navigation.navigate('SwapDetails', { swapId: item.id })}
    >
      <View style={styles.swapHeader}>
        <View style={styles.swapInfo}>
          <Text style={styles.stationName}>{item.stationName || 'Unknown Station'}</Text>
          <Text style={styles.swapDate}>
            {new Date(item.initiatedAt).toLocaleString()}
          </Text>
        </View>
        <View
          style={[
            styles.statusBadge,
            { backgroundColor: getStatusColor(item.status) },
          ]}
        >
          <Text style={styles.statusText}>{item.status.toUpperCase()}</Text>
        </View>
      </View>

      <View style={styles.swapDetails}>
        <View style={styles.detailItem}>
          <Text style={styles.detailLabel}>Swap ID</Text>
          <Text style={styles.detailValue}>{item.id}</Text>
        </View>

        <View style={styles.detailItem}>
          <Text style={styles.detailLabel}>Cost</Text>
          <Text style={styles.detailValue}>GHS {item.cost}</Text>
        </View>

        {item.duration && (
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Duration</Text>
            <Text style={styles.detailValue}>{item.duration} min</Text>
          </View>
        )}
      </View>

      <Text style={styles.viewDetails}>View Details →</Text>
    </TouchableOpacity>
  );

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyIcon}>📜</Text>
      <Text style={styles.emptyTitle}>No Swap History</Text>
      <Text style={styles.emptyText}>
        Your completed swaps will appear here
      </Text>
      <TouchableOpacity
        style={styles.findStationsButton}
        onPress={() => navigation.navigate('StationMap')}
      >
        <Text style={styles.findStationsText}>Find Stations</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Swap History</Text>
        <View style={{ width: 60 }} />
      </View>

      {/* Swap List */}
      <FlatList
        data={history}
        renderItem={renderSwap}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={() => fetchHistory()} />
        }
        ListEmptyComponent={renderEmpty}
      />

      {/* Pagination Info */}
      {history.length > 0 && (
        <View style={styles.paginationInfo}>
          <Text style={styles.paginationText}>
            Showing {history.length} of {historyTotal} swaps
          </Text>
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
  swapCard: {
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
  swapHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  swapInfo: {
    flex: 1,
  },
  stationName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  swapDate: {
    fontSize: 12,
    color: '#999',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  statusText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  swapDetails: {
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
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  viewDetails: {
    fontSize: 14,
    color: '#2ecc71',
    fontWeight: '600',
    marginTop: 12,
    textAlign: 'right',
  },
  emptyState: {
    alignItems: 'center',
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
    marginBottom: 24,
  },
  findStationsButton: {
    backgroundColor: '#2ecc71',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 25,
  },
  findStationsText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  paginationInfo: {
    backgroundColor: '#fff',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    alignItems: 'center',
  },
  paginationText: {
    fontSize: 12,
    color: '#666',
  },
});
