import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:queuewise/shared/models/analytics_model.dart';

/// Analytics repository implementation
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final FirebaseFirestore firestore;

  AnalyticsRepositoryImpl({required this.firestore});

  @override
  Future<List<AnalyticsModel>> getOrganisationAnalytics(String organisationId) async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.analyticsCollection)
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting organisation analytics: $e');
      throw DatabaseException('Failed to load analytics');
    }
  }

  @override
  Future<List<AnalyticsModel>> getServiceAnalytics(
    String organisationId,
    String serviceId,
  ) async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.analyticsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting service analytics: $e');
      throw DatabaseException('Failed to load service analytics');
    }
  }

  @override
  Future<List<AnalyticsModel>> getAnalyticsByDateRange(
    String organisationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.analyticsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting analytics by date range: $e');
      throw DatabaseException('Failed to load analytics');
    }
  }
}
