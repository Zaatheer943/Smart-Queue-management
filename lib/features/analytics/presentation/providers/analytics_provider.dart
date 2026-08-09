import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/analytics/data/analytics_repository_impl.dart';
import 'package:queuewise/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:queuewise/shared/models/analytics_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// Analytics state
class AnalyticsState {
  final List<AnalyticsModel> analytics;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState({
    this.analytics = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    List<AnalyticsModel>? analytics,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Analytics state notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(AnalyticsState());

  /// Load organisation analytics
  Future<void> loadOrganisationAnalytics(String organisationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final analytics = await _repository.getOrganisationAnalytics(organisationId);
      state = state.copyWith(analytics: analytics, isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics',
      );
    }
  }

  /// Load service analytics
  Future<void> loadServiceAnalytics(String organisationId, String serviceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final analytics = await _repository.getServiceAnalytics(organisationId, serviceId);
      state = state.copyWith(analytics: analytics, isLoading: false);
    } on DatabaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load service analytics',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Analytics provider (requires organisationId)
final analyticsProviderFamily =
    StateNotifierProvider.family<AnalyticsNotifier, AnalyticsState, String>(
  (ref, organisationId) {
    final repository = ref.watch(analyticsRepositoryProvider);
    final notifier = AnalyticsNotifier(repository);
    // Load analytics when provider is created
    notifier.loadOrganisationAnalytics(organisationId);
    return notifier;
  },
);
