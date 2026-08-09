import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:queuewise/features/authentication/domain/entities/auth_user.dart';
import 'package:queuewise/features/authentication/domain/repositories/auth_repository.dart';
import 'package:queuewise/shared/models/user_model.dart';

/// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.firestore,
  });

  @override
  Stream<AuthUser?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return AuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
      );
    });
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.currentUser;
      if (firebaseUser == null) return null;

      // Fetch user role from Firestore
      final userDoc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      final role = userDoc.data()?['role'] as String? ?? AppConstants.roleCustomer;
      final name = userDoc.data()?['name'] as String?;

      return AuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        name: name,
        role: role,
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final userDoc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw const AuthException('User document not found');
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String? ?? AppConstants.roleCustomer;
      final name = userData['name'] as String?;

      return AuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        name: name,
        role: role,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final firebaseUser = await remoteDataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        role: AppConstants.roleCustomer, // Default to customer role
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notificationEnabled: true,
      );

      await firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      return AuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        name: name,
        role: AppConstants.roleCustomer,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Registration error: $e');
      throw AuthException('Failed to register user');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('Failed to send password reset email');
    }
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserData(UserModel user) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toFirestore()..['updatedAt'] = Timestamp.fromDate(DateTime.now()));
    } catch (e) {
      throw AuthException('Failed to update user data');
    }
  }

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': token});
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Map Firebase Auth exceptions to app exceptions
  AuthException _mapFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException('No user found with this email');
      case 'wrong-password':
        return const AuthException('Incorrect password');
      case 'email-already-in-use':
        return const AuthException('Email is already registered');
      case 'invalid-email':
        return const AuthException('Invalid email address');
      case 'weak-password':
        return const AuthException('Password is too weak');
      case 'user-disabled':
        return const AuthException('This account has been disabled');
      case 'too-many-requests':
        return const AuthException('Too many requests. Please try again later');
      default:
        return AuthException(e.message ?? 'Authentication failed');
    }
  }
}
