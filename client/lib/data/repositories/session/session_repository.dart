import 'package:flutter/foundation.dart';

import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/safe_notifier.dart';

/// Session state, which every screen reads and the router redirects on.
abstract class SessionRepository extends ChangeNotifier with SafeNotifier {
  User? get currentUser;
  String? get accessToken;
  bool get isRestoring;
  bool get isSignedIn => currentUser != null;
  bool get canManageRequests => currentUser?.role.isSupportStaff ?? false;

  /// 💫 Restores the session from the local storage, if any.
  Future<Result<User?>> restore();

  /// Signs in the user with the given [email] and [password].
  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  /// Signs out the current user and clears the session.
  Future<Result<void>> signOut();
}
