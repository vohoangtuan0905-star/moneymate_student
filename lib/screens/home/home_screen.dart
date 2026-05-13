import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
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
      body: StreamBuilder<List<TransactionModel>>(
        stream: transactionService.getTransactionsByUser(user.uid),
        builder: (context, snapshot) {
          final List<TransactionModel> transactions = snapshot.data ?? [];

          final double totalIncome = _calculateTotalIncome(transactions);
          final double totalExpense = _calculateTotalExpense(transactions);
          final double balance = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
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
                          'Xin chào, ${user.displayName ?? 'Sinh viên'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Theo dõi thu chi cá nhân, quản lý số dư và chuyển đổi tiền tệ bằng API bên thứ ba.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Lỗi tải thống kê: ${snapshot.error}',
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
                const SizedBox(height: 16),
                _buildTransactionInfoBox(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildTransactionInfoBox() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cloud_done,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 12),
            Text(
              'Dữ liệu lưu trên Cloud Firestore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Trang chủ hiển thị tổng thu, tổng chi và số dư được tính trực tiếp từ dữ liệu giao dịch đã lưu trên cơ sở dữ liệu đám mây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
          ],
        ),
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
              backgroundColor: color.withOpacity(0.12),
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