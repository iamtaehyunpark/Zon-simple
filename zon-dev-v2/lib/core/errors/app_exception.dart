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

class LocationError extends AppException {
  @override
  final String message;
  const LocationError(this.message);
}

class PhotoError extends AppException {
  @override
  final String message;
  const PhotoError(this.message);
}

class NotFoundError extends AppException {
  @override
  final String message;
  const NotFoundError(this.message);
}
