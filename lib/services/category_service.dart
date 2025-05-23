import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'auth_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) => CategoryService());

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
});

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get categories for current user
  Stream<List<Category>> getCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  // Add new category
  Future<void> addCategory({
    required String userId,
    required String name,
    required String icon,
    required String color,
    required double monthlyBudget,
  }) async {
    final categoriesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');

    await categoriesRef.add({
      'name': name,
      'icon': icon,
      'color': color,
      'monthlyBudget': monthlyBudget,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update category
  Future<void> updateCategory({
    required String userId,
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    double? monthlyBudget,
  }) async {
    final categoryRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId);

    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (monthlyBudget != null) updates['monthlyBudget'] = monthlyBudget;

    await categoryRef.update(updates);
  }

  // Delete category
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // Update budget for a category
  Future<void> updateCategoryBudget({
    required String userId,
    required String categoryId,
    required double monthlyBudget,
  }) async {
    await updateCategory(
      userId: userId,
      categoryId: categoryId,
      monthlyBudget: monthlyBudget,
    );
  }
} 