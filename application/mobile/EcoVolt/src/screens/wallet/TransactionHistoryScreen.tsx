/**
 * Transaction History Screen
 * Requirements: 6.2
 * Shows complete transaction history with pagination
 */

import React, { useEffect, useState } from 'react';
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
import { RootState } from '../../store';
import {
  fetchTransactionsStart,
  fetchTransactionsSuccess,
  fetchTransactionsFailure,
} from '../../store/slices/walletSlice';
import { getTransactionHistory } from '../../services/walletService';
import { WalletTransaction } from '../../types/wallet';

export default function TransactionHistoryScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { transactions, loading, currency, transactionPage, transactionTotal } =
    useSelector((state: RootState) => state.wallet);

  const [filterType, setFilterType] = useState<string | undefined>(undefined);

  useEffect(() => {
    fetchTransactions();
  }, [filterType]);

  const fetchTransactions = async (page = 1) => {
    dispatch(fetchTransactionsStart());
    try {
      const data = await getTransactionHistory({
        page,
        pageSize: 20,
        type: filterType,
      });
      dispatch(
        fetchTransactionsSuccess({
          transactions: data.transactions,
          total: data.total,
          page: data.page,
        })
      );
    } catch (error: any) {
      dispatch(fetchTransactionsFailure(error.message));
    }
  };

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case 'topup':
        return '💰';
      case 'swap':
        return '⚡';
      case 'refund':
        return '↩️';
      case 'adjustment':
        return '⚙️';
      default:
        return '💳';
    }
  };

  const getTransactionColor = (type: string) => {
    switch (type) {
      case 'topup':
      case 'refund':
        return '#2ecc71';
      case 'swap':
        return '#e74c3c';
      case 'adjustment':
        return '#3498db';
      default:
        return '#666';
    }
  };

  const renderTransaction = ({ item }: { item: WalletTransaction }) => (
    <View style={styles.transactionCard}>
      <View style={styles.transactionIcon}>
        <Text style={styles.transactionIconText}>{getTransactionIcon(item.type)}</Text>
      </View>

      <View style={styles.transactionInfo}>
        <Text style={styles.transactionDescription}>{item.description}</Text>
        <Text style={styles.transactionDate}>
          {new Date(item.createdAt).toLocaleString()}
        </Text>
        <Text style={styles.transactionId}>ID: {item.id}</Text>
      </View>

      <View style={styles.transactionAmount}>
        <Text
          style={[
            styles.transactionAmountText,
            { color: getTransactionColor(item.type) },
          ]}
        >
          {item.type === 'topup' || item.type === 'refund' ? '+' : '-'}
          {currency} {Math.abs(item.amount).toFixed(2)}
        </Text>
        <Text style={styles.transactionStatus}>{item.status}</Text>
      </View>
    </View>
  );

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyIcon}>📭</Text>
      <Text style={styles.emptyTitle}>No Transactions</Text>
      <Text style={styles.emptyText}>
        {filterType
          ? `No ${filterType} transactions found`
          : 'Your transaction history will appear here'}
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
        <Text style={styles.headerTitle}>Transaction History</Text>
        <View style={{ width: 60 }} />
      </View>

      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, !filterType && styles.filterTabActive]}
          onPress={() => setFilterType(undefined)}
        >
          <Text style={[styles.filterText, !filterType && styles.filterTextActive]}>
            All
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.filterTab,
            filterType === 'topup' && styles.filterTabActive,
          ]}
          onPress={() => setFilterType('topup')}
        >
          <Text
            style={[
              styles.filterText,
              filterType === 'topup' && styles.filterTextActive,
            ]}
          >
            Top-ups
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.filterTab, filterType === 'swap' && styles.filterTabActive]}
          onPress={() => setFilterType('swap')}
        >
          <Text
            style={[
              styles.filterText,
              filterType === 'swap' && styles.filterTextActive,
            ]}
          >
            Swaps
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.filterTab,
            filterType === 'refund' && styles.filterTabActive,
          ]}
          onPress={() => setFilterType('refund')}
        >
          <Text
            style={[
              styles.filterText,
              filterType === 'refund' && styles.filterTextActive,
            ]}
          >
            Refunds
          </Text>
        </TouchableOpacity>
      </View>

      {/* Transaction List */}
      <FlatList
        data={transactions}
        renderItem={renderTransaction}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={() => fetchTransactions()} />
        }
        ListEmptyComponent={renderEmpty}
      />

      {/* Pagination Info */}
      {transactions.length > 0 && (
        <View style={styles.paginationInfo}>
          <Text style={styles.paginationText}>
            Showing {transactions.length} of {transactionTotal} transactions
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
  filterContainer: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  filterTab: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 8,
  },
  filterTabActive: {
    backgroundColor: '#2ecc71',
  },
  filterText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '600',
  },
  filterTextActive: {
    color: '#fff',
  },
  listContent: {
    padding: 16,
  },
  transactionCard: {
    backgroundColor: '#fff',
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  transactionIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f5f5f5',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  transactionIconText: {
    fontSize: 20,
  },
  transactionInfo: {
    flex: 1,
  },
  transactionDescription: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  transactionDate: {
    fontSize: 12,
    color: '#999',
    marginBottom: 2,
  },
  transactionId: {
    fontSize: 10,
    color: '#ccc',
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
  },
  transactionAmount: {
    alignItems: 'flex-end',
  },
  transactionAmountText: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  transactionStatus: {
    fontSize: 10,
    color: '#999',
    textTransform: 'uppercase',
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
