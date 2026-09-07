import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

import '../fixtures.dart';

/// An in-memory session, so a screen can be exercised signed in as anyone.
///
/// [signIn] accepts any credentials and returns [signInAs] — authenticating is
/// the real repository's job, and a test of a *settings* screen has no business
/// depending on it.
class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository({User? user = kStaff, this.signInAs = kStaff})
    : _currentUser = user;

  /// Who a successful [signIn] produces.
  final User signInAs;

  /// When set, [signIn] fails with it instead of succeeding.
  Exception? signInFailure;

  User? _currentUser;
  final bool _isRestoring = false;

  /// Net [addListener] minus [removeListener] calls.
  ///
  /// A view model that subscribes to the session in its constructor has to give
  /// that subscription back when it is disposed. This is how a test can see
  /// whether it did — see test/bugs/viewmodel_lifetime_test.dart. Compare
  /// deltas rather than absolute values: `provider` and `GoRouter` hold
  /// subscriptions of their own for as long as the app is up.
  int get listenerCount => _listenerCount;
  int _listenerCount = 0;

  @override
  void addListener(VoidCallback listener) {
    _listenerCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listenerCount--;
    super.removeListener(listener);
  }

  @override
  User? get currentUser => _currentUser;

  @override
  String? get accessToken => _currentUser == null ? null : 'fake-token';

  @override
  bool get isRestoring => _isRestoring;

  @override
  Future<Result<User?>> restore() async {
    notifyListeners();
    return Result.ok(_currentUser);
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    final failure = signInFailure;
    if (failure != null) return Result.error(failure);

    _currentUser = signInAs;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    notifyListeners();
    return const Result.ok(null);
  }
}
