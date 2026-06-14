sealed class AppException implements Exception {
  const AppException();

  String get message;
}

class NetworkError extends AppException {
  @override
  final String message;
  final int? statusCode;
  const NetworkError(this.message, {this.statusCode});
}

class AuthError extends AppException {
  @override
  final String message;
  const AuthError(this.message);
}

/// User-facing input problem (e.g. an ID that's already taken or malformed).
class ValidationError extends AppException {
  @override
  final String message;
  const ValidationError(this.message);
}
