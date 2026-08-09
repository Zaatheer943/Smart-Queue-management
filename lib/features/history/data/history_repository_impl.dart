import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/history/domain/repositories/history_repository.dart';
import 'package:queuewise/shared/models/queue_history_model.dart';

/// History repository implementation
class HistoryRepositoryImpl implements HistoryRepository {
  final FirebaseFirestore firestore;

  HistoryRepositoryImpl({required this.firestore});

  @override
  Future<List<QueueHistoryModel>> getUserQueueHistory(String userId) async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.queueHistoryCollection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => QueueHistoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user queue history: $e');
      throw DatabaseException('Failed to load queue history');
    }
  }

  @override
  Future<List<QueueHistoryModel>> getOrganisationHistory(String organisationId) async {
    try {
      // Get all users' history for this organisation
      final usersSnapshot = await firestore
          .collection(AppConstants.usersCollection)
          .get();

      final allHistory = <QueueHistoryModel>[];

      for (final userDoc in usersSnapshot.docs) {
        final historySnapshot = await firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.queueHistoryCollection)
            .where('organisationId', isEqualTo: organisationId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        final history = historySnapshot.docs
            .map((doc) => QueueHistoryModel.fromFirestore(doc))
            .toList();

        allHistory.addAll(history);
      }

      // Sort by date
      allHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allHistory;
    } catch (e) {
      debugPrint('Error getting organisation history: $e');
      throw DatabaseException('Failed to load organisation history');
    }
  }
}
