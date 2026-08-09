/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(String message) : super(message);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

/// Firestore/database exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message) : super(message);
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(String message) : super(message);
}

/// Server exceptions
class ServerException extends AppException {
  const ServerException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}
