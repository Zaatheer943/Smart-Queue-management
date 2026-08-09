import 'package:cloud_firestore/cloud_firestore.dart';

/// Organisation model
class OrganisationModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String email;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganisationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create OrganisationModel from Firestore document
  factory OrganisationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganisationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert OrganisationModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  OrganisationModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganisationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
