/// Authentication user entity
class AuthUser {
  final String uid;
  final String? email;
  final String? name;
  final String? role;

  AuthUser({
    required this.uid,
    this.email,
    this.name,
    this.role,
  });

  /// Check if user is authenticated
  bool get isAuthenticated => uid.isNotEmpty;

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is customer
  bool get isCustomer => role == 'customer';

  /// Create empty/unauthenticated user
  factory AuthUser.empty() {
    return AuthUser(uid: '');
  }
}
