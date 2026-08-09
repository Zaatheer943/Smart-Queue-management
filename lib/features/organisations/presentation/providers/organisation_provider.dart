import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/organisations/data/organisation_repository_impl.dart';
import 'package:queuewise/features/organisations/domain/repositories/organisation_repository.dart';
import 'package:queuewise/shared/models/organisation_model.dart';
import 'package:queuewise/shared/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Organisation repository provider
final organisationRepositoryProvider = Provider<OrganisationRepository>((ref) {
  return OrganisationRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

/// Organisations state
class OrganisationsState {
  final List<OrganisationModel> organisations;
  final bool isLoading;
  final String? errorMessage;

  OrganisationsState({
    this.organisations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrganisationsState copyWith({
    List<OrganisationModel>? organisations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrganisationsState(
      organisations: organisations ?? this.organisations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Organisations state notifier
class OrganisationsNotifier extends StateNotifier<OrganisationsState> {
  final OrganisationRepository _repository;

  OrganisationsNotifier(this._repository) : super(OrganisationsState());

  /// Load organisations
  Future<void> loadOrganisations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final organisations = await _repository.getOrganisations();
      state = state.copyWith(
        organisations: organisations,
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
        errorMessage: 'Failed to load organisations',
      );
    }
  }

  /// Search organisations
  Future<void> searchOrganisations(String query) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final organisations = await _repository.searchOrganisations(query);
      state = state.copyWith(
        organisations: organisations,
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
        errorMessage: 'Failed to search organisations',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Organisations provider
final organisationsProvider =
    StateNotifierProvider<OrganisationsNotifier, OrganisationsState>((ref) {
  final repository = ref.watch(organisationRepositoryProvider);
  final notifier = OrganisationsNotifier(repository);
  // Load organisations on initialization
  notifier.loadOrganisations();
  return notifier;
});

/// Services state
class ServicesState {
  final List<ServiceModel> services;
  final bool isLoading;
  final String? errorMessage;

  ServicesState({
    this.services = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ServicesState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Services state notifier
class ServicesNotifier extends StateNotifier<ServicesState> {
  final OrganisationRepository _repository;

  ServicesNotifier(this._repository) : super(ServicesState());

  /// Load services for an organisation
  Future<void> loadServices(String organisationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final services = await _repository.getServices(organisationId);
      state = state.copyWith(
        services: services,
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
        errorMessage: 'Failed to load services',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Services provider (requires organisationId)
final servicesProviderFamily =
    StateNotifierProvider.family<ServicesNotifier, ServicesState, String>(
  (ref, organisationId) {
    final repository = ref.watch(organisationRepositoryProvider);
    final notifier = ServicesNotifier(repository);
    // Load services when provider is created
    notifier.loadServices(organisationId);
    return notifier;
  },
);
