import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/history/data/history_repository_impl.dart';
import 'package:queuewise/features/history/domain/repositories/history_repository.dart';
import 'package:queuewise/shared/models/queue_history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// History repository provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// History state
class HistoryState {
  final List<QueueHistoryModel> history;
  final bool isLoading;
  final String? errorMessage;

  HistoryState({
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HistoryState copyWith({
    List<QueueHistoryModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// History state notifier
class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super(HistoryState());

  /// Load user's queue history
  Future<void> loadUserHistory(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final history = await _repository.getUserQueueHistory(userId);
      state = state.copyWith(history: history, isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load queue history',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// History provider (requires userId)
final historyProviderFamily =
    StateNotifierProvider.family<HistoryNotifier, HistoryState, String>(
  (ref, userId) {
    final repository = ref.watch(historyRepositoryProvider);
    final notifier = HistoryNotifier(repository);
    // Load history when provider is created
    notifier.loadUserHistory(userId);
    return notifier;
  },
);

/// Current user's history provider
final currentUserHistoryProvider = Provider<HistoryState>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;
  
  if (userId == null) {
    return HistoryState();
  }
  
  return ref.watch(historyProviderFamily(userId));
});
