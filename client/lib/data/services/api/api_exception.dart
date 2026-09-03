sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Cannot reach the server. Check that it is running and try again.',
  ]);
}

final class HttpException extends ApiException {
  const HttpException(
    this.statusCode,
    super.message, {
    this.fieldErrors = const {},
  });

  final int statusCode;

  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400 || statusCode == 422;
}

final class ParseException extends ApiException {
  const ParseException(super.message);
}

String messageFor(Object error) => switch (error) {
  ApiException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
