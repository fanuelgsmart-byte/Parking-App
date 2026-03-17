class ServerException implements Exception {

  const ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {

  const CacheException({required this.message});
  final String message;
}

class NetworkException implements Exception {

  const NetworkException({
    this.message = 'No internet connection available.',
  });
  final String message;
}

class AuthException implements Exception {

  const AuthException({required this.message});
  final String message;
}
