import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/core/errors/failures.dart';
import 'package:queuewise/features/authentication/data/auth_repository_impl.dart';
import 'package:queuewise/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:queuewise/features/authentication/domain/entities/auth_user.dart';
import 'package:queuewise/features/authentication/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Auth remote data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

/// Firestore provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Authentication state
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => user != null && user!.isAuthenticated;
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState()) {
    _init();
  }

  /// Initialize authentication state
  Future<void> _init() async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authRepository.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: 'Failed to initialize authentication',
      );
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    _authRepository.authStateChanges.listen((user) {
      state = state.copyWith(user: user);
    });
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Register new user
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authRepository.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.signOut();
      state = AuthState(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sign out',
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send password reset email',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repository);
  notifier.listenToAuthChanges();
  return notifier;
});

/// Current user provider
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Is admin provider
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});
