/// Base failure class for handling errors
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Firestore/database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
