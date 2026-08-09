import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the system
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationEnabled;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.notificationEnabled = true,
    this.fcmToken,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notificationEnabled: data['notificationEnabled'] as bool? ?? true,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  /// Convert UserModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notificationEnabled': notificationEnabled,
      'fcmToken': fcmToken,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificationEnabled,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is customer
  bool get isCustomer => role == 'customer';
}
