/// Every failure the data layer can produce, as one type the UI can switch on.
///
/// These are the `Exception` payload carried inside a `Result.error`. The point
/// is that a screen never sees an `http` type or a raw `FormatException` — it
/// sees an [ApiException] with a message that is safe to show.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection, DNS failure, or the request timed out.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Cannot reach the server. Check that it is running and try again.',
  ]);
}

/// The server answered, but with a non-2xx status.
final class HttpException extends ApiException {
  const HttpException(
    this.statusCode,
    super.message, {
    this.fieldErrors = const {},
  });

  final int statusCode;

  /// Field-level messages from the server's validation pipe, keyed by field
  /// name, so a form can show the error next to the input that caused it.
  final Map<String, String> fieldErrors;

  /// The token is missing, expired or rejected — the session is over.
  bool get isUnauthorized => statusCode == 401;

  /// Authenticated, but not allowed to do this. Distinct from [isUnauthorized]
  /// because signing in again would not help.
  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400 || statusCode == 422;
}

/// The response was not the shape this app expects — a contract mismatch
/// between client and server, not a user error.
final class ParseException extends ApiException {
  const ParseException(super.message);
}

/// Turns any thrown object into a message worth showing a user.
String messageFor(Object error) => switch (error) {
  ApiException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
