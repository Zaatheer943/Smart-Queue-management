import 'package:cloud_firestore/cloud_firestore.dart';

/// Service model
class ServiceModel {
  final String id;
  final String organisationId;
  final String name;
  final String description;
  final bool active;
  final int averageServiceDuration; // in minutes
  final int notificationThreshold; // people ahead
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.organisationId,
    required this.name,
    required this.description,
    this.active = true,
    this.averageServiceDuration = 5,
    this.notificationThreshold = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ServiceModel from Firestore document
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      organisationId: data['organisationId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      averageServiceDuration: data['averageServiceDuration'] as int? ?? 5,
      notificationThreshold: data['notificationThreshold'] as int? ?? 2,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ServiceModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'organisationId': organisationId,
      'name': name,
      'description': description,
      'active': active,
      'averageServiceDuration': averageServiceDuration,
      'notificationThreshold': notificationThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ServiceModel copyWith({
    String? id,
    String? organisationId,
    String? name,
    String? description,
    bool? active,
    int? averageServiceDuration,
    int? notificationThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      averageServiceDuration: averageServiceDuration ?? this.averageServiceDuration,
      notificationThreshold: notificationThreshold ?? this.notificationThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
