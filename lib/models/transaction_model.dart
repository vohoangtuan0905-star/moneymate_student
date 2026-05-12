import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'expense',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      note: data['note'] ?? '',
      date: _convertToDateTime(data['date']),
      createdAt: _convertToDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _convertToDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  bool get isIncome {
    return type == 'income';
  }

  bool get isExpense {
    return type == 'expense';
  }
}