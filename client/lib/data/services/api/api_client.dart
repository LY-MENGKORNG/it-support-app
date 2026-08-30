import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_history.dart';
import 'package:app/domain/models/session.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/json.dart';
import 'package:app/utils/result.dart';

import 'api_exception.dart';

/// The app's single HTTP data source.
///
/// A service in this architecture wraps *one* external source, holds no state,
/// and never throws across a layer boundary — every method hands back a
/// [Result], so a caller cannot forget that the call might fail.
///
/// It knows about endpoints and JSON. It knows nothing about caching, sessions
/// or which screen asked; that is the repositories' job.
class ApiClient {
  ApiClient({
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

  /// Supplies the bearer token for each request, or null when signed out.
  ///
  /// A callback rather than a stored string so the client always reads the
  /// *current* token: it is wired to the session repository in
  /// `config/dependencies.dart`, and neither object has to know when the other
  /// changes. It is not final because the client and the session each need the
  /// other: `dependencies.dart` builds the client first, then closes the loop.
  String? Function()? authTokenProvider;

  /// Called when the server rejects our token.
  ///
  /// The service cannot sign anyone out — that is session state, which lives in
  /// a repository — so it reports the fact and lets the session decide. This is
  /// what turns an expired token into a trip to the login screen rather than an
  /// error on every screen at once.
  void Function()? onUnauthorized;

  /// `localhost` means "this device", which on an Android emulator is the
  /// emulator itself, not the machine running the server. 10.0.2.2 is the
  /// emulator's alias for the host loopback.
  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // -------------------------------------------------------------------- auth

  /// Exchanges credentials for a token.
  ///
  /// Sent unauthenticated on purpose: a stale token must not be able to affect
  /// whether a fresh sign-in succeeds.
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) => _sendObject(
    'POST',
    '/auth/login',
    Session.fromJson,
    body: {'email': email, 'password': password},
    authenticated: false,
  );

  /// Who the stored token belongs to — how a saved session is restored.
  Future<Result<User>> getCurrentUser() =>
      _getObject('/auth/me', User.fromJson);

  // ---------------------------------------------------------------- requests

  Future<Result<RequestPage>> getRequests(RequestFilters filters) => _getObject(
    '/request',
    RequestPage.fromJson,
    query: filters.toQueryParameters(),
  );

  Future<Result<RequestDetail>> getRequest(int id) =>
      _getObject('/request/$id', RequestDetail.fromJson);

  Future<Result<RequestDetail>> postRequest(NewRequest draft) => _sendObject(
    'POST',
    '/request',
    RequestDetail.fromJson,
    body: draft.toJson(),
  );

  Future<Result<RequestDetail>> patchRequest(int id, RequestPatch patch) =>
      _sendObject(
        'PATCH',
        '/request/$id',
        RequestDetail.fromJson,
        body: patch.toJson(),
      );

  // ---------------------------------------------------------------- comments

  Future<Result<List<Comment>>> getComments(int requestId) =>
      _getList('/request/$requestId/comment', Comment.fromJson);

  /// The author is not sent: the server takes it from the token, so a client
  /// has no way to post a comment under someone else's name.
  Future<Result<Comment>> postComment(
    int requestId, {
    required String content,
  }) => _sendObject(
    'POST',
    '/request/$requestId/comment',
    Comment.fromJson,
    body: {'content': content},
  );

  Future<Result<List<RequestHistory>>> getHistory(int requestId) =>
      _getList('/request/$requestId/history', RequestHistory.fromJson);

  // ------------------------------------------------------------------- users

  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit = 50,
    int offset = 0,
  }) => _getList(
    '/user',
    User.fromJson,
    query: {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (role != null) 'role': role.wire,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Staff and admins — the only people a request can be assigned to.
  Future<Result<List<User>>> getAssignableUsers() =>
      _getList('/user/assignable', User.fromJson);

  Future<Result<User>> getUser(int id) =>
      _getObject('/user/$id', User.fromJson);

  // -------------------------------------------------------------- categories

  Future<Result<List<RequestCategory>>> getCategories() =>
      _getList('/category', RequestCategory.fromJson);

  void dispose() => _client.close();

  // ------------------------------------------------------------------ plumbing

  Future<Result<T>> _getObject<T>(
    String path,
    T Function(Json) parse, {
    Map<String, dynamic>? query,
  }) => _sendObject('GET', path, parse, query: query);

  Future<Result<T>> _sendObject<T>(
    String method,
    String path,
    T Function(Json) parse, {
    Map<String, dynamic>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final result = await _send(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );

    return switch (result) {
      Error<dynamic>(:final error) => Result.error(error),
      Ok<dynamic>(:final value) => _parse(
        () => value is Json
            ? parse(value)
            : throw ParseException(
                'Expected a JSON object, got ${value.runtimeType}.',
              ),
      ),
    };
  }

  Future<Result<List<T>>> _getList<T>(
    String path,
    T Function(Json) parse, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _send('GET', path, query: query);

    return switch (result) {
      Error<dynamic>(:final error) => Result.error(error),
      Ok<dynamic>(:final value) => _parse(
        () => value is List
            ? value.cast<Json>().map(parse).toList(growable: false)
            : throw ParseException(
                'Expected a JSON array, got ${value.runtimeType}.',
              ),
      ),
    };
  }

  /// Parsing sits behind its own try/catch so a contract mismatch surfaces as a
  /// [ParseException] rather than escaping as a bare `FormatException`.
  Result<T> _parse<T>(T Function() build) {
    try {
      return Result.ok(build());
    } on ApiException catch (exception) {
      return Result.error(exception);
    } on FormatException catch (exception) {
      return Result.error(ParseException(exception.message));
    } on TypeError catch (exception) {
      return Result.error(
        ParseException('Unexpected response shape: $exception'),
      );
    }
  }

  Future<Result<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
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

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      return const Result.error(
        NetworkException('The server took too long to respond.'),
      );
    } on SocketException catch (exception) {
      return Result.error(
        NetworkException(
          'Cannot reach $baseUrl (${exception.osError?.message ?? 'no connection'}).',
        ),
      );
    } on http.ClientException catch (exception) {
      return Result.error(NetworkException(exception.message));
    }

    if (response.statusCode >= 400) {
      final error = _errorFor(response);

      // A 401 on an authenticated call means the token we hold is no longer
      // good. Signing in is the one place where a 401 is an ordinary answer
      // ("wrong password") rather than a dead session, hence the flag.
      if (authenticated && error is HttpException && error.isUnauthorized) {
        onUnauthorized?.call();
      }
      return Result.error(error);
    }
    if (response.body.isEmpty) return const Result.ok(null);

    try {
      return Result.ok(jsonDecode(response.body));
    } on FormatException {
      return const Result.error(
        ParseException('The server returned a malformed response.'),
      );
    }
  }

  /// Query values are dropped when null so callers can pass optional filters
  /// straight through without building the map conditionally.
  Uri _uri(String path, Map<String, dynamic>? query) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;

    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return uri.replace(queryParameters: params.isEmpty ? null : params);
  }

  /// Nest sends `{ message, errors: [{ path, message }] }` for validation
  /// failures and `{ message }` otherwise. Anything else falls back to the
  /// status line, because an unparseable error is still an error.
  ApiException _errorFor(http.Response response) {
    String message = 'Request failed (${response.statusCode}).';
    final fieldErrors = <String, String>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Json) {
        final raw = decoded['message'];
        if (raw is String && raw.isNotEmpty) {
          message = raw;
        } else if (raw is List && raw.isNotEmpty) {
          message = raw.join('\n');
        }

        for (final issue in (decoded['errors'] as List? ?? const [])) {
          if (issue is Map && issue['path'] is String) {
            fieldErrors[issue['path'] as String] = '${issue['message']}';
          }
        }
        if (fieldErrors.isNotEmpty) {
          message = fieldErrors.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n');
        }
      }
    } on FormatException {
      // Keep the status-line fallback.
    }

    return HttpException(
      response.statusCode,
      message,
      fieldErrors: fieldErrors,
    );
  }
}
