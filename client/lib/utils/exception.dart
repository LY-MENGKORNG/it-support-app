/// An exception that occurs when an API call fails.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// An exception that occurs when the API returns a response that cannot be parsed.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Cannot reach the server. Check that it is running and try again.',
  ]);
}

/// An exception that occurs when the API returns a response that cannot be parsed.
final class HttpException extends ApiException {
  final int statusCode;
  final Map<String, String> fieldErrors;

  const HttpException(
    this.statusCode,
    super.message, {
    this.fieldErrors = const {},
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400 || statusCode == 422;
}

/// An exception that occurs when the API returns a response that cannot be parsed.
final class ParseException extends ApiException {
  const ParseException(super.message);
}

String messageFor(Object error) => switch (error) {
  ApiException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
