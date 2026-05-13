import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    return _firestore.collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsCollection.add(transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id.isEmpty) {
      throw Exception('Không tìm thấy ID giao dịch để cập nhật.');
    }

    await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (transactionId.isEmpty) {
      throw Exception('Không tìm thấy ID giao dịch để xóa.');
    }

    await _transactionsCollection.doc(transactionId).delete();
  }

  Stream<List<TransactionModel>> getTransactionsByUser(String userId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<TransactionModel> transactions = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        return TransactionModel.fromMap(
          id: doc.id,
          data: data,
        );
      }).toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    });
  }
}