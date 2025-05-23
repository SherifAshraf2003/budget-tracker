import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import 'auth_service.dart';

final expenseServiceProvider = Provider<ExpenseService>((ref) => ExpenseService());

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
});

// Provider for current month expenses
final currentMonthExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(microseconds: 1));
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('expenses')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
});

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add new expense
  Future<void> addExpense({
    required String userId,
    required String categoryId,
    required String categoryName,
    required String description,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final expensesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses');

    await expensesRef.add({
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update expense
  Future<void> updateExpense({
    required String userId,
    required String expenseId,
    String? categoryId,
    String? categoryName,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
  }) async {
    final expenseRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId);

    Map<String, dynamic> updates = {};
    if (categoryId != null) updates['categoryId'] = categoryId;
    if (categoryName != null) updates['categoryName'] = categoryName;
    if (description != null) updates['description'] = description;
    if (amount != null) updates['amount'] = amount;
    if (date != null) updates['date'] = Timestamp.fromDate(date);
    if (notes != null) updates['notes'] = notes;

    await expenseRef.update(updates);
  }

  // Delete expense
  Future<void> deleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // Get expenses for specific category
  Stream<List<Expense>> getExpensesByCategory(String userId, String categoryId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  // Get expenses for date range
  Stream<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  // Get total spending for current month by category
  Future<Map<String, double>> getCurrentMonthSpendingByCategory(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(microseconds: 1));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    Map<String, double> spendingByCategory = {};
    for (var doc in snapshot.docs) {
      final expense = Expense.fromFirestore(doc);
      spendingByCategory[expense.categoryId] = 
          (spendingByCategory[expense.categoryId] ?? 0.0) + expense.amount;
    }

    return spendingByCategory;
  }

  // Get total spending for current month
  Future<double> getCurrentMonthTotalSpending(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(microseconds: 1));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final expense = Expense.fromFirestore(doc);
      total += expense.amount;
    }

    return total;
  }
} 