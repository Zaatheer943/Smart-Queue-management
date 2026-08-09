import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/admin/domain/repositories/admin_repository.dart';
import 'package:queuewise/features/queues/domain/services/queue_calculation_service.dart';
import 'package:queuewise/shared/models/queue_model.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Admin repository implementation
class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore firestore;

  AdminRepositoryImpl({required this.firestore});

  @override
  Future<TokenModel?> callNextToken(String queueId) async {
    try {
      return await firestore.runTransaction((transaction) async {
        // Extract organisationId from queueId
        final parts = queueId.split('_');
        if (parts.length < 2) {
          throw DatabaseException('Invalid queue ID format');
        }
        final organisationId = parts[0];

        final queueRef = firestore
            .collection(AppConstants.organisationsCollection)
            .doc(organisationId)
            .collection(AppConstants.queuesCollection)
            .doc(queueId);

        final queueDoc = await transaction.get(queueRef);
        if (!queueDoc.exists) {
          throw DatabaseException('Queue not found');
        }

        // Get next waiting token
        final tokensQuery = queueRef
            .collection(AppConstants.tokensCollection)
            .where('status', isEqualTo: AppConstants.tokenStatusWaiting)
            .orderBy('tokenNumber')
            .limit(1);

        final tokensSnapshot = await tokensQuery.get();
        if (tokensSnapshot.docs.isEmpty) {
          return null; // No waiting tokens
        }

        final tokenDoc = tokensSnapshot.docs.first;
        final token = TokenModel.fromFirestore(tokenDoc);

        // Validate status transition
        if (!QueueCalculationService.isValidStatusTransition(
              token.status,
              AppConstants.tokenStatusCalled,
            )) {
          throw DatabaseException('Invalid status transition');
        }

        // Update token status to called
        transaction.update(tokenDoc.reference, {
          'status': AppConstants.tokenStatusCalled,
          'calledAt': Timestamp.fromDate(DateTime.now()),
        });

        // Update queue current serving number
        transaction.update(queueRef, {
          'currentServingNumber': token.tokenNumber,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        return token.copyWith(
          status: AppConstants.tokenStatusCalled,
          calledAt: DateTime.now(),
        );
      });
    } on DatabaseException {
      rethrow;
    } catch (e) {
      debugPrint('Error calling next token: $e');
      throw DatabaseException('Failed to call next token');
    }
  }

  @override
  Future<void> markTokenAsServing(String tokenId) async {
    try {
      await _updateTokenStatus(
        tokenId,
        AppConstants.tokenStatusServing,
      );
    } catch (e) {
      debugPrint('Error marking token as serving: $e');
      throw DatabaseException('Failed to mark token as serving');
    }
  }

  @override
  Future<void> markTokenAsServed(String tokenId) async {
    try {
      await _updateTokenStatus(
        tokenId,
        AppConstants.tokenStatusServed,
        servedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error marking token as served: $e');
      throw DatabaseException('Failed to mark token as served');
    }
  }

  @override
  Future<void> markTokenAsNoShow(String tokenId) async {
    try {
      await _updateTokenStatus(
        tokenId,
        AppConstants.tokenStatusNoShow,
      );
    } catch (e) {
      debugPrint('Error marking token as no-show: $e');
      throw DatabaseException('Failed to mark token as no-show');
    }
  }

  Future<void> _updateTokenStatus(
    String tokenId,
    String newStatus, {
    DateTime? servedAt,
  }) async {
    // Search for token across organisations
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

        final tokenSnapshot = await tokenRef.get();
        if (tokenSnapshot.exists) {
          final token = TokenModel.fromFirestore(tokenSnapshot);

          // Validate status transition
          if (!QueueCalculationService.isValidStatusTransition(
                token.status,
                newStatus,
              )) {
            throw DatabaseException('Invalid status transition');
          }

          final updates = <String, dynamic>{
            'status': newStatus,
          };

          if (servedAt != null) {
            updates['servedAt'] = Timestamp.fromDate(servedAt);
          }

          await tokenRef.update(updates);

          // Update queue stats if token is completed
          if (newStatus == AppConstants.tokenStatusServed ||
              newStatus == AppConstants.tokenStatusNoShow ||
              newStatus == AppConstants.tokenStatusCancelled) {
            final queueRef = firestore
                .collection(AppConstants.organisationsCollection)
                .doc(orgDoc.id)
                .collection(AppConstants.queuesCollection)
                .doc(queueDoc.id);

            final queueSnapshot = await queueRef.get();
            if (queueSnapshot.exists) {
              final queue = QueueModel.fromFirestore(queueSnapshot);
              await queueRef.update({
                'totalWaiting': queue.totalWaiting - 1 > 0 ? queue.totalWaiting - 1 : 0,
                'updatedAt': Timestamp.fromDate(DateTime.now()),
              });
            }
          }

          return;
        }
      }
    }

    throw DatabaseException('Token not found');
  }

  @override
  Future<List<TokenModel>> getWaitingTokens(String queueId) async {
    try {
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
      debugPrint('Error getting waiting tokens: $e');
      throw DatabaseException('Failed to load waiting tokens');
    }
  }

  @override
  Future<TokenModel?> getCurrentServingToken(String queueId) async {
    try {
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
          .where('status', whereIn: [
            AppConstants.tokenStatusCalled,
            AppConstants.tokenStatusServing,
          ])
          .orderBy('tokenNumber')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return TokenModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting current serving token: $e');
      throw DatabaseException('Failed to load current serving token');
    }
  }
}
