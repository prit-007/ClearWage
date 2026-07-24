class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthException extends ApiException {
  AuthException([String message = 'Unauthorized']) : super(message);
}

class ServerException extends ApiException {
  ServerException([String message = 'Server error']) : super(message);
}
