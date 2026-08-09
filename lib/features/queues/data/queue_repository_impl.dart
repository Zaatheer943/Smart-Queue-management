import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/queues/domain/repositories/queue_repository.dart';
import 'package:queuewise/shared/models/queue_model.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Queue repository implementation with atomic token generation
class QueueRepositoryImpl implements QueueRepository {
  final FirebaseFirestore firestore;

  QueueRepositoryImpl({required this.firestore});

  @override
  Future<QueueModel> getOrCreateQueue(
    String organisationId,
    String serviceId,
  ) async {
    try {
      // Try to get existing queue
      final queueDoc = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.queuesCollection)
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (queueDoc.docs.isNotEmpty) {
        return QueueModel.fromFirestore(queueDoc.docs.first);
      }

      // Create new queue
      final newQueueRef = firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.queuesCollection)
          .doc();

      final newQueue = QueueModel(
        id: newQueueRef.id,
        organisationId: organisationId,
        serviceId: serviceId,
        currentServingNumber: 0,
        nextTokenNumber: 1,
        active: true,
        averageServiceDuration: AppConstants.defaultAverageServiceDuration,
        totalWaiting: 0,
        updatedAt: DateTime.now(),
      );

      await newQueueRef.set(newQueue.toFirestore());
      return newQueue;
    } catch (e) {
      debugPrint('Error getting/creating queue: $e');
      throw DatabaseException('Failed to get or create queue');
    }
  }

  @override
  Future<QueueModel?> getQueue(String queueId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(queueId.split('_')[0]) // Extract organisationId from queueId
          .collection(AppConstants.queuesCollection)
          .doc(queueId)
          .get();

      if (!doc.exists) return null;
      return QueueModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting queue: $e');
      throw DatabaseException('Failed to load queue');
    }
  }

  @override
  Future<TokenModel> joinQueue({
    required String organisationId,
    required String serviceId,
    required String userId,
  }) async {
    try {
      // First, get or create queue outside transaction
      final queueQuery = firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.queuesCollection)
          .where('serviceId', isEqualTo: serviceId)
          .limit(1);

      final queueSnapshot = await queueQuery.get();
      DocumentReference queueDocRef;
      QueueModel queue;

      if (queueSnapshot.docs.isEmpty) {
        // Create new queue
        queueDocRef = firestore
            .collection(AppConstants.organisationsCollection)
            .doc(organisationId)
            .collection(AppConstants.queuesCollection)
            .doc();

        final newQueue = QueueModel(
          id: queueDocRef.id,
          organisationId: organisationId,
          serviceId: serviceId,
          currentServingNumber: 0,
          nextTokenNumber: 1,
          active: true,
          averageServiceDuration: AppConstants.defaultAverageServiceDuration,
          totalWaiting: 0,
          updatedAt: DateTime.now(),
        );

        await queueDocRef.set(newQueue.toFirestore());
        queue = newQueue;
      } else {
        queueDocRef = queueSnapshot.docs.first.reference;
        queue = QueueModel.fromFirestore(queueSnapshot.docs.first);
      }

      // Now use transaction for token generation
      return await firestore.runTransaction((transaction) async {
        // Check if user already has an active token
        final existingTokensQuery = firestore
            .collection(AppConstants.organisationsCollection)
            .doc(organisationId)
            .collection(AppConstants.queuesCollection)
            .doc(queue.id)
            .collection(AppConstants.tokensCollection)
            .where('userId', isEqualTo: userId)
            .where('status', whereIn: [
              AppConstants.tokenStatusWaiting,
              AppConstants.tokenStatusCalled,
              AppConstants.tokenStatusServing,
            ]);

        final existingTokensSnapshot = await existingTokensQuery.get();
        if (existingTokensSnapshot.docs.isNotEmpty) {
          throw DatabaseException('You already have an active token in this queue');
        }

        // Get latest queue state
        final queueDoc = await transaction.get(queueDocRef);
        final latestQueue = QueueModel.fromFirestore(queueDoc);

        // Generate next token number atomically
        final nextTokenNumber = latestQueue.nextTokenNumber;
        final updatedQueue = latestQueue.copyWith(
          nextTokenNumber: nextTokenNumber + 1,
          totalWaiting: latestQueue.totalWaiting + 1,
          updatedAt: DateTime.now(),
        );

        transaction.update(queueDocRef, updatedQueue.toFirestore());

        // Create token
        final tokenRef = queueDocRef.collection(AppConstants.tokensCollection).doc();
        final estimatedWait = (latestQueue.totalWaiting * latestQueue.averageServiceDuration);

        final token = TokenModel(
          id: tokenRef.id,
          queueId: queue.id,
          organisationId: organisationId,
          serviceId: serviceId,
          userId: userId,
          tokenNumber: nextTokenNumber,
          status: AppConstants.tokenStatusWaiting,
          joinedAt: DateTime.now(),
          estimatedWaitMinutes: estimatedWait,
        );

        transaction.set(tokenRef, token.toFirestore());

        return token;
      });
    } on DatabaseException {
      rethrow;
    } catch (e) {
      debugPrint('Error joining queue: $e');
      throw DatabaseException('Failed to join queue');
    }
  }

  @override
  Future<TokenModel?> getUserActiveToken(String userId) async {
    try {
      // Search across all organisations for user's active token
      final orgsSnapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .get();

      for (final orgDoc in orgsSnapshot.docs) {
        final queuesSnapshot = await firestore
            .collection(AppConstants.organisationsCollection)
            .doc(orgDoc.id)
            .collection(AppConstants.queuesCollection)
            .get();

        for (final queueDoc in queuesSnapshot.docs) {
          final tokensSnapshot = await firestore
              .collection(AppConstants.organisationsCollection)
              .doc(orgDoc.id)
              .collection(AppConstants.queuesCollection)
              .doc(queueDoc.id)
              .collection(AppConstants.tokensCollection)
              .where('userId', isEqualTo: userId)
              .where('status', whereIn: [
                AppConstants.tokenStatusWaiting,
                AppConstants.tokenStatusCalled,
                AppConstants.tokenStatusServing,
              ])
              .limit(1)
              .get();

          if (tokensSnapshot.docs.isNotEmpty) {
            return TokenModel.fromFirestore(tokensSnapshot.docs.first);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user active token: $e');
      throw DatabaseException('Failed to get active token');
    }
  }

  @override
  Future<void> cancelToken(String tokenId) async {
    try {
      await firestore.runTransaction((transaction) async {
        // Find the token document
        // Note: In production, you'd need to know the organisationId and queueId
        // For now, we'll search across all organisations
        final orgsSnapshot = await firestore
            .collection(AppConstants.organisationsCollection)
            .get();

        for (final orgDoc in orgsSnapshot.docs) {
          final queuesSnapshot = await firestore
              .collection(AppConstants.organisationsCollection)
              .doc(orgDoc.id)
              .collection(AppConstants.queuesCollection)
              .get();

          for (final queueDoc in queuesSnapshot.docs) {
            final tokenRef = firestore
                .collection(AppConstants.organisationsCollection)
                .doc(orgDoc.id)
                .collection(AppConstants.queuesCollection)
                .doc(queueDoc.id)
                .collection(AppConstants.tokensCollection)
                .doc(tokenId);

            final tokenSnapshot = await transaction.get(tokenRef);
            if (tokenSnapshot.exists) {
              final token = TokenModel.fromFirestore(tokenSnapshot);
              if (!token.isActive) {
                throw DatabaseException('Token is already completed');
              }

              // Update token status
              transaction.update(tokenRef, {
                'status': AppConstants.tokenStatusCancelled,
                'cancelledAt': Timestamp.fromDate(DateTime.now()),
              });

              // Update queue stats
              final queueRef = firestore
                  .collection(AppConstants.organisationsCollection)
                  .doc(orgDoc.id)
                  .collection(AppConstants.queuesCollection)
                  .doc(queueDoc.id);

              final queueSnapshot = await transaction.get(queueRef);
              if (queueSnapshot.exists) {
                final queue = QueueModel.fromFirestore(queueSnapshot);
                transaction.update(queueRef, {
                  'totalWaiting': queue.totalWaiting - 1 > 0 ? queue.totalWaiting - 1 : 0,
                  'updatedAt': Timestamp.fromDate(DateTime.now()),
                });
              }

              return;
            }
          }
        }

        throw DatabaseException('Token not found');
      });
    } on DatabaseException {
      rethrow;
    } catch (e) {
      debugPrint('Error cancelling token: $e');
      throw DatabaseException('Failed to cancel token');
    }
  }

  @override
  Future<List<TokenModel>> getQueueTokens(String queueId) async {
    try {
      // Extract organisationId from queueId (assumes format: orgId_queueId)
      final parts = queueId.split('_');
      if (parts.length < 2) {
        throw DatabaseException('Invalid queue ID format');
      }

      final organisationId = parts[0];

      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.queuesCollection)
          .doc(queueId)
          .collection(AppConstants.tokensCollection)
          .where('status', isEqualTo: AppConstants.tokenStatusWaiting)
          .orderBy('tokenNumber')
          .get();

      return snapshot.docs
          .map((doc) => TokenModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting queue tokens: $e');
      throw DatabaseException('Failed to load queue tokens');
    }
  }

  @override
  Future<int> calculatePeopleAhead(String queueId, int tokenNumber) async {
    try {
      final tokens = await getQueueTokens(queueId);
      return tokens.where((token) => token.tokenNumber < tokenNumber).length;
    } catch (e) {
      debugPrint('Error calculating people ahead: $e');
      return 0;
    }
  }

  @override
  Future<void> updateQueueStats(String queueId, int totalWaiting) async {
    try {
      final parts = queueId.split('_');
      if (parts.length < 2) {
        throw DatabaseException('Invalid queue ID format');
      }

      final organisationId = parts[0];

      await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.queuesCollection)
          .doc(queueId)
          .update({
            'totalWaiting': totalWaiting,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      debugPrint('Error updating queue stats: $e');
      throw DatabaseException('Failed to update queue stats');
    }
  }
}
