import 'package:flutter/foundation.dart';

import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/safe_notifier.dart';

/// Session state, which every screen reads and the router redirects on.
///
/// [SafeNotifier] here rather than on the implementation: this object outlives
/// every screen, and all three of its notifications land after an `await`.
abstract class SessionRepository extends ChangeNotifier with SafeNotifier {
  User? get currentUser;
  String? get accessToken;
  bool get isRestoring;

  bool get isSignedIn => currentUser != null;
  bool get canManageRequests => currentUser?.role.isSupportStaff ?? false;

  Future<Result<User?>> restore();

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
