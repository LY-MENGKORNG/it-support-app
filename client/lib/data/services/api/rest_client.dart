import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:app/utils/json.dart';
import 'package:app/utils/result.dart';

import 'api_exception.dart';

typedef Query = Map<String, dynamic>;

typedef Decoder<T> = T Function(Object? payload);

Decoder<T> asObject<T>(ParseFn<T> parse) {
  return (payload) {
    if (payload is JsonType) {
      return parse(payload);
    }
    throw ParseException('Expected a JSON object, got ${payload.runtimeType}.');
  };
}

Decoder<List<T>> asList<T>(ParseFn<T> parse) {
  return (payload) {
    if (payload is List) {
      return payload.cast<JsonType>().map(parse).toList(growable: false);
    }
    throw ParseException('Expected a JSON array, got ${payload.runtimeType}.');
  };
}

class RestClient {
  RestClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.authTokenProvider,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  String? Function()? authTokenProvider;

  void Function()? onUnauthorized;

  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<Result<T>> get<T>(String path, Decoder<T> decode, {Query? query}) =>
      send('GET', path, decode, query: query);

  Future<Result<T>> post<T>(
    String path,
    Decoder<T> decode, {
    Object? body,
    bool authenticated = true,
  }) => send('POST', path, decode, body: body, authenticated: authenticated);

  Future<Result<T>> patch<T>(String path, Decoder<T> decode, {Object? body}) =>
      send('PATCH', path, decode, body: body);

  Future<Result<T>> send<T>(
    String method,
    String path,
    Decoder<T> decode, {
    Query? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final payload = await _payload(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );

    return payload.flatMap(
      (value) => Result.safeTry(() => decode(value), onError: _asParseFailure),
    );
  }

  void dispose() => _client.close();

  Future<Result<dynamic>> _payload(
    String method,
    String path, {
    Query? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, _uri(path, query))
      ..headers['accept'] = 'application/json';

    if (authenticated) {
      final token = authTokenProvider?.call();
      if (token != null) request.headers['authorization'] = 'Bearer $token';
    }

    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await Result.safeTryAsync(
      () => _exchange(request),
      onError: _asNetworkFailure,
    );

    return response.flatMap(
      (response) => _read(response, authenticated: authenticated),
    );
  }

  /// One deadline over the whole exchange: reaching the server, its status
  /// line, and reading the body to the end.
  ///
  /// Two separate `timeout`s of [timeout] each would make the field's promise —
  /// how long a call may take — a lie by a factor of two, so the second phase
  /// gets whatever is left of the first.
  Future<http.Response> _exchange(http.Request request) async {
    final deadline = DateTime.now().add(timeout);
    final streamed = await _client.send(request).timeout(timeout);

    return _collect(streamed, within: deadline.difference(DateTime.now()));
  }

  /// The body, or a [TimeoutException] with the socket hung up.
  ///
  /// `Response.fromStream(...).timeout(...)` reads as the same thing and is
  /// not: `timeout` abandons the *future*, while the subscription underneath it
  /// goes on waiting for bytes — and goes on holding the connection. A server
  /// that answers and then stalls mid-body would leak one socket per attempt
  /// until the pool is empty, at which point the next call blocks inside `send`
  /// before its own deadline is even armed, and the hang is back a layer down.
  /// Cancelling the subscription is what actually hangs up.
  Future<http.Response> _collect(
    http.StreamedResponse streamed, {
    required Duration within,
  }) async {
    final chunks = <int>[];
    final finished = Completer<void>();
    final subscription = streamed.stream.listen(
      chunks.addAll,
      onDone: finished.complete,
      onError: finished.completeError,
      cancelOnError: true,
    );

    try {
      await finished.future.timeout(within);
    } on TimeoutException {
      await subscription.cancel();
      rethrow;
    }

    return http.Response.bytes(
      chunks,
      streamed.statusCode,
      request: streamed.request,
      headers: streamed.headers,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );
  }

  Result<dynamic> _read(http.Response response, {required bool authenticated}) {
    if (response.statusCode >= 400) {
      final error = _errorFor(response);

      if (authenticated && error is HttpException && error.isUnauthorized) {
        onUnauthorized?.call();
      }
      return Result.error(error);
    }
    if (response.body.isEmpty) return const Result.ok(null);

    return Result.safeTry(
      () => jsonDecode(response.body),
      onError: (_, _) =>
          const ParseException('The server returned a malformed response.'),
    );
  }

  Exception _asNetworkFailure(Object error, StackTrace stackTrace) =>
      switch (error) {
        TimeoutException() => const NetworkException(
          'The server took too long to respond.',
        ),
        SocketException(:final osError) => NetworkException(
          'Cannot reach $baseUrl (${osError?.message ?? 'no connection'}).',
        ),
        http.ClientException(:final message) => NetworkException(message),
        _ => rethrowWithStack(error, stackTrace),
      };

  Exception _asParseFailure(Object error, StackTrace stackTrace) =>
      switch (error) {
        ApiException() => error,
        FormatException(:final message) => ParseException(message),
        TypeError() => ParseException('Unexpected response shape: $error'),
        _ => rethrowWithStack(error, stackTrace),
      };

  Uri _uri(String path, Query? query) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;

    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return uri.replace(queryParameters: params.isEmpty ? null : params);
  }

  ApiException _errorFor(http.Response response) {
    final body = _bodyOf(response);
    final fieldErrors = <String, String>{
      for (final issue in body['errors'] as List? ?? const [])
        if (issue is Map && issue['path'] is String)
          issue['path'] as String: '${issue['message']}',
    };

    return HttpException(
      response.statusCode,
      _messageIn(body, fieldErrors) ??
          'Request failed (${response.statusCode}).',
      fieldErrors: fieldErrors,
    );
  }

  JsonType _bodyOf(http.Response response) =>
      switch (Result.safeTry(() => jsonDecode(response.body))) {
        Ok(value: final JsonType body) => body,
        _ => const {},
      };

  String? _messageIn(JsonType body, Map<String, String> fieldErrors) {
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }

    return switch (body['message']) {
      final String message when message.isNotEmpty => message,
      final List<dynamic> messages when messages.isNotEmpty => messages.join(
        '\n',
      ),
      _ => null,
    };
  }
}
