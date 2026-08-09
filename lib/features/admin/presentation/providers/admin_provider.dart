import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/admin/data/admin_repository_impl.dart';
import 'package:queuewise/features/admin/domain/repositories/admin_repository.dart';
import 'package:queuewise/shared/models/token_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin repository provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// Admin state
class AdminState {
  final TokenModel? currentServingToken;
  final List<TokenModel> waitingTokens;
  final bool isLoading;
  final String? errorMessage;

  AdminState({
    this.currentServingToken,
    this.waitingTokens = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminState copyWith({
    TokenModel? currentServingToken,
    List<TokenModel>? waitingTokens,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminState(
      currentServingToken: currentServingToken ?? this.currentServingToken,
      waitingTokens: waitingTokens ?? this.waitingTokens,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Admin state notifier
class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repository;

  AdminNotifier(this._repository) : super(AdminState());

  /// Load queue data
  Future<void> loadQueueData(String queueId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.getCurrentServingToken(queueId),
        _repository.getWaitingTokens(queueId),
      ]);

      state = state.copyWith(
        currentServingToken: results[0] as TokenModel?,
        waitingTokens: results[1] as List<TokenModel>,
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
        errorMessage: 'Failed to load queue data',
      );
    }
  }

  /// Call next token
  Future<TokenModel?> callNextToken(String queueId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repository.callNextToken(queueId);
      if (token != null) {
        // Reload queue data
        await loadQueueData(queueId);
      }
      state = state.copyWith(isLoading: false);
      return token;
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to call next token',
      );
      return null;
    }
  }

  /// Mark token as serving
  Future<void> markAsServing(String tokenId, String queueId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.markTokenAsServing(tokenId);
      await loadQueueData(queueId);
      state = state.copyWith(isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to mark token as serving',
      );
    }
  }

  /// Mark token as served
  Future<void> markAsServed(String tokenId, String queueId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.markTokenAsServed(tokenId);
      await loadQueueData(queueId);
      state = state.copyWith(isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to mark token as served',
      );
    }
  }

  /// Mark token as no-show
  Future<void> markAsNoShow(String tokenId, String queueId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.markTokenAsNoShow(tokenId);
      await loadQueueData(queueId);
      state = state.copyWith(isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to mark token as no-show',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Admin provider (requires queueId)
final adminProviderFamily =
    StateNotifierProvider.family<AdminNotifier, AdminState, String>(
  (ref, queueId) {
    final repository = ref.watch(adminRepositoryProvider);
    final notifier = AdminNotifier(repository);
    // Load queue data when provider is created
    notifier.loadQueueData(queueId);
    return notifier;
  },
);
