import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../currency/currency_converter_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/transaction_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final AuthService authService = AuthService();

    await authService.logout();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _goToAddTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
  }

  void _goToTransactionList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionListScreen(),
      ),
    );
  }

  void _goToCurrencyConverter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CurrencyConverterScreen(),
      ),
    );
  }

  String _formatMoney(double amount) {
    final String value = amount.toStringAsFixed(0);
    final RegExp regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');

    return '${value.replaceAllMapped(regExp, (match) => '.')}đ';
  }

  double _calculateTotalIncome(List<TransactionModel> transactions) {
    double total = 0;

    for (final TransactionModel transaction in transactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  double _calculateTotalExpense(List<TransactionModel> transactions) {
    double total = 0;

    for (final TransactionModel transaction in transactions) {
      if (transaction.isExpense) {
        total += transaction.amount;
      }
    }

    return total;
  }

  List<TransactionModel> _getRecentTransactions(
    List<TransactionModel> transactions,
  ) {
    final List<TransactionModel> recentTransactions = List.from(transactions);

    recentTransactions.sort((a, b) => b.date.compareTo(a.date));

    if (recentTransactions.length > 3) {
      return recentTransactions.take(3).toList();
    }

    return recentTransactions;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getUserProfileStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  String _getDisplayName({
    required User user,
    required DocumentSnapshot<Map<String, dynamic>>? userSnapshot,
  }) {
    final Map<String, dynamic>? data = userSnapshot?.data();

    final String? firestoreName = data?['name']?.toString().trim();

    if (firestoreName != null && firestoreName.isNotEmpty) {
      return firestoreName;
    }

    final String? authName = user.displayName?.trim();

    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    return 'Sinh viên';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Bạn cần đăng nhập để xem trang chủ.'),
        ),
      );
    }

    final TransactionService transactionService = TransactionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('MoneyMate Student'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getUserProfileStream(user.uid),
        builder: (context, userSnapshot) {
          final String displayName = _getDisplayName(
            user: user,
            userSnapshot: userSnapshot.data,
          );

          return StreamBuilder<List<TransactionModel>>(
            stream: transactionService.getTransactionsByUser(user.uid),
            builder: (context, transactionSnapshot) {
              final List<TransactionModel> transactions =
                  transactionSnapshot.data ?? [];

              final double totalIncome = _calculateTotalIncome(transactions);
              final double totalExpense = _calculateTotalExpense(transactions);
              final double balance = totalIncome - totalExpense;
              final List<TransactionModel> recentTransactions =
                  _getRecentTransactions(transactions);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildWelcomeCard(
                      displayName: displayName,
                      email: user.email ?? '',
                    ),
                    const SizedBox(height: 20),
                    if (transactionSnapshot.connectionState ==
                        ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (transactionSnapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Không thể tải dữ liệu: ${transactionSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Tổng thu',
                            value: _formatMoney(totalIncome),
                            icon: Icons.arrow_downward,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Tổng chi',
                            value: _formatMoney(totalExpense),
                            icon: Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Số dư hiện tại',
                      value: _formatMoney(balance),
                      icon: Icons.savings,
                      color: balance >= 0 ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      title: 'Số giao dịch',
                      value: transactions.length.toString(),
                      icon: Icons.receipt_long,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 20),
                    _buildRecentTransactionsSection(
                      context: context,
                      transactions: recentTransactions,
                    ),
                    const SizedBox(height: 16),
                    _buildCurrencyInfoBox(context),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard({
    required String displayName,
    required String email,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Xin chào, $displayName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quản lý thu chi cá nhân, theo dõi số dư và xem nhanh các giao dịch gần đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _goToAddTransaction(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _goToTransactionList(context),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Danh sách'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _goToCurrencyConverter(context),
            icon: const Icon(Icons.currency_exchange),
            label: const Text('Chuyển đổi tiền tệ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection({
    required BuildContext context,
    required List<TransactionModel> transactions,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Giao dịch gần đây',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _goToTransactionList(context),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 52,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Chưa có giao dịch nào',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: transactions.map((transaction) {
                  return _RecentTransactionItem(
                    transaction: transaction,
                    formatMoney: _formatMoney,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyInfoBox(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.currency_exchange,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chuyển đổi tiền tệ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quy đổi nhanh giữa VND, USD, EUR, JPY, KRW và một số loại tiền phổ biến khác.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _goToCurrencyConverter(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Mở chuyển đổi tiền tệ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double amount) formatMoney;

  const _RecentTransactionItem({
    required this.transaction,
    required this.formatMoney,
  });

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.isIncome;
    final Color color = isIncome ? Colors.green : Colors.red;
    final IconData icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.note.isEmpty
                      ? _formatDate(transaction.date)
                      : '${transaction.note} • ${_formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${formatMoney(transaction.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}