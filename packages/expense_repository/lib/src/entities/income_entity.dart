import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeEntity {
  final String id;
  final String source;
  final DateTime date;
  final double amount;

  IncomeEntity({
    required this.id,
    required this.source,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'id': id,
      'source': source,
      'date': Timestamp.fromDate(date),
      'amount': amount,
    };
  }

  static IncomeEntity fromDocument(Map<String, dynamic> doc) {
    return IncomeEntity(
      id: doc['id'] as String,
      source: doc['source'] as String,
      date: (doc['date'] as Timestamp).toDate(),
      amount: (doc['amount'] as num).toDouble(),
    );
  }
}
