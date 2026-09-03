import 'package:app/data/services/api/auth_api.dart';
import 'package:app/data/services/local/shared_preference_service.dart';
import 'package:app/domain/models/session.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

import 'session_repository.dart';

class RemoteSessionRepository extends SessionRepository {
  RemoteSessionRepository({required this._auth, required this._preferences});

  final AuthApi _auth;
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
    _isRestoring = true;

    try {
      final stored = await _preferences.fetchToken();
      if (stored is Error<String?>) {
        return Result.error(stored.error);
      }

      final token = stored.asOk.value;
      if (token == null) {
        return const Result.ok(null);
      }

      _accessToken = token;

      final user = await _auth.currentUser();
      switch (user) {
        case Ok<User>(:final value):
          _currentUser = value;
          return Result.ok(value);
        case Error<User>():
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
    final result = await _auth.login(email: email, password: password);

    switch (result) {
      case Ok<Session>(:final value):
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
    _accessToken = null;
    _currentUser = null;
    notifyListeners();

    return _preferences.removeToken();
  }
}
