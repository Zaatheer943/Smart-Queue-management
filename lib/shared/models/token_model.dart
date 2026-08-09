import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queuewise/app/constants/app_constants.dart';

/// Token model
class TokenModel {
  final String id;
  final String queueId;
  final String organisationId;
  final String serviceId;
  final String userId;
  final int tokenNumber;
  final String status;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? servedAt;
  final DateTime? cancelledAt;
  final int estimatedWaitMinutes;

  TokenModel({
    required this.id,
    required this.queueId,
    required this.organisationId,
    required this.serviceId,
    required this.userId,
    required this.tokenNumber,
    this.status = AppConstants.tokenStatusWaiting,
    required this.joinedAt,
    this.calledAt,
    this.servedAt,
    this.cancelledAt,
    this.estimatedWaitMinutes = 0,
  });

  /// Create TokenModel from Firestore document
  factory TokenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TokenModel(
      id: doc.id,
      queueId: data['queueId'] as String? ?? '',
      organisationId: data['organisationId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      tokenNumber: data['tokenNumber'] as int? ?? 0,
      status: data['status'] as String? ?? AppConstants.tokenStatusWaiting,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      servedAt: (data['servedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      estimatedWaitMinutes: data['estimatedWaitMinutes'] as int? ?? 0,
    );
  }

  /// Convert TokenModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'queueId': queueId,
      'organisationId': organisationId,
      'serviceId': serviceId,
      'userId': userId,
      'tokenNumber': tokenNumber,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'calledAt': calledAt != null ? Timestamp.fromDate(calledAt!) : null,
      'servedAt': servedAt != null ? Timestamp.fromDate(servedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'estimatedWaitMinutes': estimatedWaitMinutes,
    };
  }

  /// Create a copy with updated fields
  TokenModel copyWith({
    String? id,
    String? queueId,
    String? organisationId,
    String? serviceId,
    String? userId,
    int? tokenNumber,
    String? status,
    DateTime? joinedAt,
    DateTime? calledAt,
    DateTime? servedAt,
    DateTime? cancelledAt,
    int? estimatedWaitMinutes,
  }) {
    return TokenModel(
      id: id ?? this.id,
      queueId: queueId ?? this.queueId,
      organisationId: organisationId ?? this.organisationId,
      serviceId: serviceId ?? this.serviceId,
      userId: userId ?? this.userId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      calledAt: calledAt ?? this.calledAt,
      servedAt: servedAt ?? this.servedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
    );
  }

  /// Check if token is waiting
  bool get isWaiting => status == AppConstants.tokenStatusWaiting;

  /// Check if token is called
  bool get isCalled => status == AppConstants.tokenStatusCalled;

  /// Check if token is being served
  bool get isServing => status == AppConstants.tokenStatusServing;

  /// Check if token is served
  bool get isServed => status == AppConstants.tokenStatusServed;

  /// Check if token is cancelled
  bool get isCancelled => status == AppConstants.tokenStatusCancelled;

  /// Check if token is no-show
  bool get isNoShow => status == AppConstants.tokenStatusNoShow;

  /// Check if token is active (waiting, called, or serving)
  bool get isActive => isWaiting || isCalled || isServing;

  /// Check if token is completed (served, cancelled, or no-show)
  bool get isCompleted => isServed || isCancelled || isNoShow;
}
