import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

/// Authentication remote data source interface
abstract class AuthRemoteDataSource {
  /// Get current Firebase user
  firebase_auth.User? get currentUser;

  /// Get auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges;

  /// Sign in with email and password
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register with email and password
  Future<firebase_auth.User> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
}

/// Firebase Auth implementation of remote data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth? _firebaseAuth;

  AuthRemoteDataSourceImpl() 
      : _firebaseAuth = _tryInitializeFirebaseAuth();

  static firebase_auth.FirebaseAuth? _tryInitializeFirebaseAuth() {
    try {
      return firebase_auth.FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not configured: $e');
      return null;
    }
  }

  @override
  firebase_auth.User? get currentUser => _firebaseAuth?.currentUser;

  @override
  Stream<firebase_auth.User?> get authStateChanges {
    if (_firebaseAuth == null) {
      return const Stream.empty();
    }
    return _firebaseAuth!.authStateChanges();
  }

  @override
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'not-configured',
        message: 'Firebase is not configured. Please run flutterfire configure.',
      );
    }

    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found',
        );
      }
      
      return credential.user!;
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: 'An unknown error occurred',
      );
    }
  }

  @override
  Future<firebase_auth.User> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'not-configured',
        message: 'Firebase is not configured. Please run flutterfire configure.',
      );
    }

    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'registration-failed',
          message: 'Registration failed',
        );
      }
      
      return credential.user!;
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Registration error: $e');
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown',
        message: 'An unknown error occurred',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_firebaseAuth == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'not-configured',
        message: 'Firebase is not configured.',
      );
    }
    try {
      await _firebaseAuth!.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw firebase_auth.FirebaseAuthException(
        code: 'signout-failed',
        message: 'Sign out failed',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (_firebaseAuth == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'not-configured',
        message: 'Firebase is not configured.',
      );
    }
    try {
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw firebase_auth.FirebaseAuthException(
        code: 'reset-failed',
        message: 'Failed to send password reset email',
      );
    }
  }
}
