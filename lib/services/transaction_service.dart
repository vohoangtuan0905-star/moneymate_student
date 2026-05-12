import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _transactionsCollection {
    return _firestore.collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsCollection.add(transaction.toMap());
  }

  Stream<List<TransactionModel>> getTransactionsByUser(String userId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<TransactionModel> transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

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