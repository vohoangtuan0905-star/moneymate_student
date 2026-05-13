import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _transactionService = TransactionService();

  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Ăn uống';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Ăn uống',
    'Di chuyển',
    'Học tập',
    'Giải trí',
    'Mua sắm',
    'Sức khỏe',
    'Khác',
  ];

  final List<String> _incomeCategories = [
    'Gia đình gửi',
    'Lương',
    'Học bổng',
    'Làm thêm',
    'Khác',
  ];

  bool get _isEditMode {
    return widget.transaction != null;
  }

  List<String> get _currentCategories {
    if (_selectedType == 'income') {
      return _incomeCategories;
    }

    return _expenseCategories;
  }

  @override
  void initState() {
    super.initState();

    final TransactionModel? transaction = widget.transaction;

    if (transaction != null) {
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
      _amountController.text = transaction.amount.toStringAsFixed(0);
      _noteController.text = transaction.note;

      if (_selectedType == 'income') {
        _selectedCategory = _incomeCategories.contains(transaction.category)
            ? transaction.category
            : _incomeCategories.first;
      } else {
        _selectedCategory = _expenseCategories.contains(transaction.category)
            ? transaction.category
            : _expenseCategories.first;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _changeTransactionType(String type) {
    setState(() {
      _selectedType = type;

      if (type == 'income') {
        _selectedCategory = _incomeCategories.first;
      } else {
        _selectedCategory = _expenseCategories.first;
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> _handleSaveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập trước khi lưu giao dịch.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final TransactionModel transaction = TransactionModel(
        id: widget.transaction?.id ?? '',
        userId: currentUser.uid,
        type: _selectedType,
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      if (_isEditMode) {
        await _transactionService.updateTransaction(transaction);
      } else {
        await _transactionService.addTransaction(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Đã cập nhật giao dịch thành công.'
                : 'Đã lưu ${transaction.isIncome ? 'khoản thu' : 'khoản chi'} vào Firestore.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu giao dịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final double? amount = double.tryParse(value.trim());

    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }

    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    return null;
  }

  Color get _typeColor {
    if (_selectedType == 'income') {
      return Colors.green;
    }

    return Colors.red;
  }

  IconData get _typeIcon {
    if (_selectedType == 'income') {
      return Icons.arrow_downward;
    }

    return Icons.arrow_upward;
  }

  String get _typeTitle {
    if (_selectedType == 'income') {
      return 'Khoản thu';
    }

    return 'Khoản chi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 18),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _typeColor.withOpacity(0.12),
                              child: Icon(
                                _typeIcon,
                                color: _typeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _typeTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        CustomTextField(
                          controller: _amountController,
                          labelText: 'Số tiền',
                          hintText: 'Ví dụ: 25000',
                          prefixIcon: Icons.payments,
                          keyboardType: TextInputType.number,
                          validator: _validateAmount,
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _noteController,
                          labelText: 'Ghi chú',
                          hintText: 'Ví dụ: Cơm trưa, tiền gửi xe...',
                          prefixIcon: Icons.note_alt,
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: _isEditMode
                              ? 'Cập nhật giao dịch'
                              : 'Lưu giao dịch',
                          isLoading: _isLoading,
                          onPressed: _handleSaveTransaction,
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeOption(
            title: 'Khoản chi',
            icon: Icons.arrow_upward,
            color: Colors.red,
            isSelected: _selectedType == 'expense',
            onTap: () => _changeTransactionType('expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeOption(
            title: 'Khoản thu',
            icon: Icons.arrow_downward,
            color: Colors.green,
            isSelected: _selectedType == 'income',
            onTap: () => _changeTransactionType('income'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Danh mục',
        prefixIcon: const Icon(Icons.category),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
      ),
      items: _currentCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày giao dịch',
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}