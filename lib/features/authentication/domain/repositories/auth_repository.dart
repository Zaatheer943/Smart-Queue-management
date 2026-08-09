import 'package:queuewise/features/authentication/domain/entities/auth_user.dart';
import 'package:queuewise/shared/models/user_model.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Get current authenticated user stream
  Stream<AuthUser?> get authStateChanges;

  /// Get current authenticated user
  Future<AuthUser?> getCurrentUser();

  /// Sign in with email and password
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register new user with email and password
  Future<AuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid);

  /// Update user data in Firestore
  Future<void> updateUserData(UserModel user);

  /// Update FCM token
  Future<void> updateFcmToken(String uid, String token);
}
