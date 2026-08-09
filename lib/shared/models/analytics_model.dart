import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics model for admin statistics
class AnalyticsModel {
  final String id;
  final String serviceId;
  final String date;
  final int totalServed;
  final int totalCancelled;
  final int totalNoShow;
  final double avgWaitTime; // in minutes
  final double avgServiceTime; // in minutes
  final int peakHour; // 0-23
  final DateTime createdAt;
  final DateTime updatedAt;

  AnalyticsModel({
    required this.id,
    required this.serviceId,
    required this.date,
    this.totalServed = 0,
    this.totalCancelled = 0,
    this.totalNoShow = 0,
    this.avgWaitTime = 0.0,
    this.avgServiceTime = 0.0,
    this.peakHour = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AnalyticsModel from Firestore document
  factory AnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsModel(
      id: doc.id,
      serviceId: data['serviceId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      totalServed: data['totalServed'] as int? ?? 0,
      totalCancelled: data['totalCancelled'] as int? ?? 0,
      totalNoShow: data['totalNoShow'] as int? ?? 0,
      avgWaitTime: (data['avgWaitTime'] as num?)?.toDouble() ?? 0.0,
      avgServiceTime: (data['avgServiceTime'] as num?)?.toDouble() ?? 0.0,
      peakHour: data['peakHour'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AnalyticsModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'serviceId': serviceId,
      'date': date,
      'totalServed': totalServed,
      'totalCancelled': totalCancelled,
      'totalNoShow': totalNoShow,
      'avgWaitTime': avgWaitTime,
      'avgServiceTime': avgServiceTime,
      'peakHour': peakHour,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  AnalyticsModel copyWith({
    String? id,
    String? serviceId,
    String? date,
    int? totalServed,
    int? totalCancelled,
    int? totalNoShow,
    double? avgWaitTime,
    double? avgServiceTime,
    int? peakHour,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalyticsModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      totalServed: totalServed ?? this.totalServed,
      totalCancelled: totalCancelled ?? this.totalCancelled,
      totalNoShow: totalNoShow ?? this.totalNoShow,
      avgWaitTime: avgWaitTime ?? this.avgWaitTime,
      avgServiceTime: avgServiceTime ?? this.avgServiceTime,
      peakHour: peakHour ?? this.peakHour,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate completion rate
  double get completionRate {
    final total = totalServed + totalCancelled + totalNoShow;
    if (total == 0) return 0.0;
    return (totalServed / total) * 100;
  }

  /// Calculate no-show rate
  double get noShowRate {
    final total = totalServed + totalCancelled + totalNoShow;
    if (total == 0) return 0.0;
    return (totalNoShow / total) * 100;
  }
}
