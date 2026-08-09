import 'package:cloud_firestore/cloud_firestore.dart';

/// Queue history model for customer's past queue visits
class QueueHistoryModel {
  final String id;
  final String organisationId;
  final String serviceId;
  final int tokenNumber;
  final String status;
  final DateTime joinedAt;
  final DateTime? servedAt;
  final int waitingDuration; // in minutes
  final int? serviceDuration; // in minutes
  final DateTime createdAt;

  QueueHistoryModel({
    required this.id,
    required this.organisationId,
    required this.serviceId,
    required this.tokenNumber,
    required this.status,
    required this.joinedAt,
    this.servedAt,
    required this.waitingDuration,
    this.serviceDuration,
    required this.createdAt,
  });

  /// Create QueueHistoryModel from Firestore document
  factory QueueHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueHistoryModel(
      id: doc.id,
      organisationId: data['organisationId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      tokenNumber: data['tokenNumber'] as int? ?? 0,
      status: data['status'] as String? ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      servedAt: (data['servedAt'] as Timestamp?)?.toDate(),
      waitingDuration: data['waitingDuration'] as int? ?? 0,
      serviceDuration: data['serviceDuration'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert QueueHistoryModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'organisationId': organisationId,
      'serviceId': serviceId,
      'tokenNumber': tokenNumber,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'servedAt': servedAt != null ? Timestamp.fromDate(servedAt!) : null,
      'waitingDuration': waitingDuration,
      'serviceDuration': serviceDuration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  QueueHistoryModel copyWith({
    String? id,
    String? organisationId,
    String? serviceId,
    int? tokenNumber,
    String? status,
    DateTime? joinedAt,
    DateTime? servedAt,
    int? waitingDuration,
    int? serviceDuration,
    DateTime? createdAt,
  }) {
    return QueueHistoryModel(
      id: id ?? this.id,
      organisationId: organisationId ?? this.organisationId,
      serviceId: serviceId ?? this.serviceId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      servedAt: servedAt ?? this.servedAt,
      waitingDuration: waitingDuration ?? this.waitingDuration,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if history entry is served
  bool get isServed => status == 'served';

  /// Check if history entry is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if history entry is no-show
  bool get isNoShow => status == 'no_show';
}
