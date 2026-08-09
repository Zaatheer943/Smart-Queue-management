import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/queues/data/queue_repository_impl.dart';
import 'package:queuewise/features/queues/domain/repositories/queue_repository.dart';
import 'package:queuewise/shared/models/queue_model.dart';
import 'package:queuewise/shared/models/token_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Queue repository provider
final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// Queue state
class QueueState {
  final TokenModel? activeToken;
  final QueueModel? queue;
  final bool isLoading;
  final String? errorMessage;

  QueueState({
    this.activeToken,
    this.queue,
    this.isLoading = false,
    this.errorMessage,
  });

  QueueState copyWith({
    TokenModel? activeToken,
    QueueModel? queue,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QueueState(
      activeToken: activeToken ?? this.activeToken,
      queue: queue ?? this.queue,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Get people ahead
  int get peopleAhead => 0; // Will be calculated separately

  /// Get estimated wait time
  int get estimatedWaitMinutes => activeToken?.estimatedWaitMinutes ?? 0;
}

/// Queue state notifier
class QueueNotifier extends StateNotifier<QueueState> {
  final QueueRepository _repository;

  QueueNotifier(this._repository) : super(QueueState());

  /// Load user's active token
  Future<void> loadActiveToken(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repository.getUserActiveToken(userId);
      state = state.copyWith(
        activeToken: token,
        isLoading: false,
      );

      // Load queue if token exists
      if (token != null) {
        final queue = await _repository.getQueue(token.queueId);
        state = state.copyWith(queue: queue);
      }
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load active token',
      );
    }
  }

  /// Join queue
  Future<void> joinQueue({
    required String organisationId,
    required String serviceId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repository.joinQueue(
        organisationId: organisationId,
        serviceId: serviceId,
        userId: userId,
      );

      // Load queue
      final queue = await _repository.getQueue(token.queueId);

      state = state.copyWith(
        activeToken: token,
        queue: queue,
        isLoading: false,
      );
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join queue',
      );
    }
  }

  /// Cancel token
  Future<void> cancelToken(String tokenId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.cancelToken(tokenId);
      state = state.copyWith(
        activeToken: null,
        queue: null,
        isLoading: false,
      );
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to cancel token',
      );
    }
  }

  /// Calculate people ahead
  Future<void> calculatePeopleAhead() async {
    final token = state.activeToken;
    if (token == null) return;

    try {
      final peopleAhead = await _repository.calculatePeopleAhead(
        token.queueId,
        token.tokenNumber,
      );
      // Update estimated wait time based on people ahead
      final avgDuration = state.queue?.averageServiceDuration ?? 5;
      final estimatedWait = peopleAhead * avgDuration;

      final updatedToken = token.copyWith(
        estimatedWaitMinutes: estimatedWait,
      );
      state = state.copyWith(activeToken: updatedToken);
    } catch (e) {
      debugPrint('Error calculating people ahead: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Queue provider (requires userId)
final queueProviderFamily =
    StateNotifierProvider.family<QueueNotifier, QueueState, String>(
  (ref, userId) {
    final repository = ref.watch(queueRepositoryProvider);
    final notifier = QueueNotifier(repository);
    // Load active token when provider is created
    notifier.loadActiveToken(userId);
    return notifier;
  },
);

/// Real-time queue stream provider
final queueStreamProvider = StreamProvider.family<QueueModel?, String>(
  (ref, queueId) {
    // Extract organisationId from queueId
    final parts = queueId.split('_');
    if (parts.length < 2) {
      return Stream.value(null);
    }
    final organisationId = parts[0];
    
    return FirebaseFirestore.instance
        .collection(AppConstants.organisationsCollection)
        .doc(organisationId)
        .collection(AppConstants.queuesCollection)
        .doc(queueId)
        .snapshots()
        .map((doc) => doc.exists ? QueueModel.fromFirestore(doc) : null);
  },
);

/// Real-time token stream provider
final tokenStreamProvider = StreamProvider.family<TokenModel?, String>(
  (ref, tokenId) {
    // Need to search for the token across organisations
    // For simplicity, we'll use a different approach
    return Stream.value(null);
  },
);
