/**
 * Wallet Screen
 * Requirements: 6.1, 6.2
 * Shows wallet balance and transaction history
 */

import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Platform,
  ScrollView,
  RefreshControl,
  Alert,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import {
  fetchBalanceStart,
  fetchBalanceSuccess,
  fetchBalanceFailure,
  fetchTransactionsStart,
  fetchTransactionsSuccess,
  fetchTransactionsFailure,
} from '../store/slices/walletSlice';
import { getWalletBalance, getTransactionHistory } from '../services/walletService';
import { WalletTransaction } from '../types/wallet';

export default function WalletScreen({ navigation }: any) {
  const dispatch = useDispatch();
  const { balance, currency, transactions, loading } = useSelector(
    (state: RootState) => state.wallet
  );

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    await Promise.all([fetchBalance(), fetchTransactions()]);
  };

  const fetchBalance = async () => {
    dispatch(fetchBalanceStart());
    try {
      const data = await getWalletBalance();
      dispatch(
        fetchBalanceSuccess({
          balance: data.balance,
          currency: data.currency,
        })
      );
    } catch (error: any) {
      dispatch(fetchBalanceFailure(error.message));
      Alert.alert('Error', error.message);
    }
  };

  const fetchTransactions = async () => {
    dispatch(fetchTransactionsStart());
    try {
      const data = await getTransactionHistory({ page: 1, pageSize: 10 });
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

  const renderTransaction = (transaction: WalletTransaction) => (
    <View key={transaction.id} style={styles.transactionCard}>
      <View style={styles.transactionIcon}>
        <Text style={styles.transactionIconText}>
          {getTransactionIcon(transaction.type)}
        </Text>
      </View>

      <View style={styles.transactionInfo}>
        <Text style={styles.transactionDescription}>{transaction.description}</Text>
        <Text style={styles.transactionDate}>
          {new Date(transaction.createdAt).toLocaleString()}
        </Text>
      </View>

      <View style={styles.transactionAmount}>
        <Text
          style={[
            styles.transactionAmountText,
            { color: getTransactionColor(transaction.type) },
          ]}
        >
          {transaction.type === 'topup' || transaction.type === 'refund' ? '+' : '-'}
          {currency} {Math.abs(transaction.amount).toFixed(2)}
        </Text>
        <Text style={styles.transactionStatus}>{transaction.status}</Text>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Wallet</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={fetchData} />}
      >
        {/* Balance Card */}
        <View style={styles.balanceCard}>
          <Text style={styles.balanceLabel}>Available Balance</Text>
          <Text style={styles.balanceAmount}>
            {currency} {balance.toFixed(2)}
          </Text>

          <TouchableOpacity
            style={styles.topUpButton}
            onPress={() => navigation.navigate('TopUp')}
          >
            <Text style={styles.topUpButtonText}>💰 Top Up Wallet</Text>
          </TouchableOpacity>
        </View>

        {/* Quick Stats */}
        <View style={styles.statsContainer}>
          <View style={styles.statCard}>
            <Text style={styles.statValue}>{transactions.length}</Text>
            <Text style={styles.statLabel}>Transactions</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statValue}>
              {transactions.filter((t) => t.type === 'swap').length}
            </Text>
            <Text style={styles.statLabel}>Swaps</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statValue}>
              {transactions.filter((t) => t.type === 'topup').length}
            </Text>
            <Text style={styles.statLabel}>Top-ups</Text>
          </View>
        </View>

        {/* Recent Transactions */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Recent Transactions</Text>
            <TouchableOpacity onPress={() => navigation.navigate('TransactionHistory')}>
              <Text style={styles.seeAllText}>See All →</Text>
            </TouchableOpacity>
          </View>

          {transactions.length === 0 ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyIcon}>📭</Text>
              <Text style={styles.emptyText}>No transactions yet</Text>
            </View>
          ) : (
            transactions.slice(0, 5).map(renderTransaction)
          )}
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
  content: {
    flex: 1,
  },
  balanceCard: {
    backgroundColor: '#2ecc71',
    margin: 16,
    padding: 24,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 5,
  },
  balanceLabel: {
    fontSize: 14,
    color: '#fff',
    opacity: 0.9,
    marginBottom: 8,
  },
  balanceAmount: {
    fontSize: 40,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 20,
  },
  topUpButton: {
    backgroundColor: '#fff',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 25,
  },
  topUpButtonText: {
    color: '#2ecc71',
    fontSize: 16,
    fontWeight: '600',
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    marginBottom: 16,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
  },
  section: {
    paddingHorizontal: 16,
    marginBottom: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  seeAllText: {
    fontSize: 14,
    color: '#2ecc71',
    fontWeight: '600',
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
    paddingVertical: 40,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  emptyText: {
    fontSize: 14,
    color: '#666',
  },
});
