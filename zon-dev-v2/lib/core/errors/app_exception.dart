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
