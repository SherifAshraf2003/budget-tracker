import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String categoryId;
  final String categoryName;
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Expense copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 