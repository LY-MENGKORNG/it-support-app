import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/shared_preferences_service.dart';
import 'package:app/domain/models/session.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

import 'session_repository.dart';

/// Bridges local storage and the API: the device remembers a *token*, the app
/// needs a *user*.
///
/// It depends on two services and on no other repository — repositories in this
/// architecture never depend on each other.
class SessionRepositoryRemote extends SessionRepository {
  SessionRepositoryRemote({
    required this._apiClient,
    required this._preferences,
  });

  final ApiClient _apiClient;
  final SharedPreferencesService _preferences;

  User? _currentUser;
  String? _accessToken;
  bool _isRestoring = true;

  @override
  User? get currentUser => _currentUser;

  @override
  String? get accessToken => _accessToken;

  @override
  bool get isRestoring => _isRestoring;

  @override
  Future<Result<User?>> restore() async {
    // Deliberately no `notifyListeners()` here. `restore` is called from
    // `MainApp.initState`, so everything before the first `await` runs while
    // the widget tree is still mounting — and the router listens to this
    // object, so notifying now marks an already-dirty element dirty again
    // ('!_dirty' assertion). The flag is set silently; the notification at the
    // end lands in a later microtask, which is safe.
    _isRestoring = true;

    try {
      final stored = await _preferences.fetchToken();
      if (stored is Error<String?>) return Result.error(stored.error);

      final token = stored.asOk.value;
      if (token == null) return const Result.ok(null);

      // Set it before the call so the API client can read it back through its
      // token provider — this *is* the request that tests whether it works.
      _accessToken = token;

      final user = await _apiClient.getCurrentUser();
      switch (user) {
        case Ok<User>(:final value):
          _currentUser = value;
          return Result.ok(value);
        case Error<User>():
          // Expired, revoked, or belonging to an account that has since been
          // deactivated. A dead token must not wedge the app on a broken
          // screen: forget it and fall back to the login form.
          _accessToken = null;
          await _preferences.removeToken();
          return const Result.ok(null);
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.login(email: email, password: password);

    switch (result) {
      case Ok<Session>(:final value):
        // The token is persisted before the session is announced, so a listener
        // reacting to the notification can never observe a signed-in app whose
        // credentials would be gone after a restart.
        final saved = await _preferences.saveToken(value.accessToken);
        if (saved is Error<void>) return saved;

        _accessToken = value.accessToken;
        _currentUser = value.user;
        notifyListeners();
        return const Result.ok(null);

      case Error<Session>(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    // The local session is cleared whatever storage says. A failed `remove`
    // must not leave the app signed in with a token the user asked to drop.
    _accessToken = null;
    _currentUser = null;
    notifyListeners();

    return _preferences.removeToken();
  }
}
