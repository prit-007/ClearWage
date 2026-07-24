class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthException extends ApiException {
  AuthException([super.message = 'Unauthorized']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Server error']);
}
