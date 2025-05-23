import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String currency,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _createUserDocument(
          userId: result.user!.uid,
          email: email,
          fullName: fullName,
          currency: currency,
        );
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email & Password Sign In
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create User Document
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String fullName,
    required String currency,
    String? photoUrl,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);

    await userDoc.set({
      'email': email,
      'fullName': fullName,
      'profilePhotoUrl': photoUrl ?? '',
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'preferences': {},
    });

    // Create default categories
    await _createDefaultCategories(userId);
  }

  // Create Default Categories
  Future<void> _createDefaultCategories(String userId) async {
    final categoriesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');

    final defaultCategories = [
      {
        'name': 'Food & Dining',
        'icon': 'restaurant',
        'color': '#FF5722',
        'monthlyBudget': 500.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Transportation',
        'icon': 'directions_car',
        'color': '#2196F3',
        'monthlyBudget': 300.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Entertainment',
        'icon': 'movie',
        'color': '#9C27B0',
        'monthlyBudget': 200.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Shopping',
        'icon': 'shopping_bag',
        'color': '#E91E63',
        'monthlyBudget': 400.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Bills & Utilities',
        'icon': 'receipt',
        'color': '#607D8B',
        'monthlyBudget': 800.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Health & Fitness',
        'icon': 'fitness_center',
        'color': '#4CAF50',
        'monthlyBudget': 150.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Travel',
        'icon': 'flight',
        'color': '#FF9800',
        'monthlyBudget': 300.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Other',
        'icon': 'category',
        'color': '#795548',
        'monthlyBudget': 100.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (var category in defaultCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, category);
    }
    await batch.commit();
  }

  // Handle Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
