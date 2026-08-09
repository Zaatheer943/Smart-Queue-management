import 'package:cloud_firestore/cloud_firestore.dart';

/// Queue model
class QueueModel {
  final String id;
  final String organisationId;
  final String serviceId;
  final int currentServingNumber;
  final int nextTokenNumber;
  final bool active;
  final int averageServiceDuration; // in minutes
  final int totalWaiting;
  final DateTime updatedAt;

  QueueModel({
    required this.id,
    required this.organisationId,
    required this.serviceId,
    required this.currentServingNumber,
    required this.nextTokenNumber,
    this.active = true,
    this.averageServiceDuration = 5,
    this.totalWaiting = 0,
    required this.updatedAt,
  });

  /// Create QueueModel from Firestore document
  factory QueueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueModel(
      id: doc.id,
      organisationId: data['organisationId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      currentServingNumber: data['currentServingNumber'] as int? ?? 0,
      nextTokenNumber: data['nextTokenNumber'] as int? ?? 1,
      active: data['active'] as bool? ?? true,
      averageServiceDuration: data['averageServiceDuration'] as int? ?? 5,
      totalWaiting: data['totalWaiting'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert QueueModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'organisationId': organisationId,
      'serviceId': serviceId,
      'currentServingNumber': currentServingNumber,
      'nextTokenNumber': nextTokenNumber,
      'active': active,
      'averageServiceDuration': averageServiceDuration,
      'totalWaiting': totalWaiting,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  QueueModel copyWith({
    String? id,
    String? organisationId,
    String? serviceId,
    int? currentServingNumber,
    int? nextTokenNumber,
    bool? active,
    int? averageServiceDuration,
    int? totalWaiting,
    DateTime? updatedAt,
  }) {
    return QueueModel(
      id: id ?? this.id,
      organisationId: organisationId ?? this.organisationId,
      serviceId: serviceId ?? this.serviceId,
      currentServingNumber: currentServingNumber ?? this.currentServingNumber,
      nextTokenNumber: nextTokenNumber ?? this.nextTokenNumber,
      active: active ?? this.active,
      averageServiceDuration: averageServiceDuration ?? this.averageServiceDuration,
      totalWaiting: totalWaiting ?? this.totalWaiting,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
