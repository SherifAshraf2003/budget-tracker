import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String profilePhotoUrl;
  final String currency;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.currency,
    required this.createdAt,
    required this.preferences,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] ?? '',
      currency: data['currency'] ?? 'USD',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'profilePhotoUrl': profilePhotoUrl,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'preferences': preferences,
    };
  }
}
