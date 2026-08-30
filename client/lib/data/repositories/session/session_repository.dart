import 'package:flutter/foundation.dart';

import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

/// Who the app is signed in as, and the token that proves it.
///
/// A [ChangeNotifier] because this is app-wide session state, and the guide
/// puts session state in the data layer rather than in a UI-layer controller:
/// the router listens to it, and so do several view models.
///
/// The token is deliberately readable — the API client needs it on every
/// request — but nothing outside this repository may *set* it. Signing in and
/// out are the only two ways it changes.
abstract class SessionRepository extends ChangeNotifier {
  /// The signed-in user, or null when nobody is.
  User? get currentUser;

  /// The bearer token for the current session, or null when signed out.
  String? get accessToken;

  /// True until the first [restore] finishes, so the router can hold on a
  /// splash instead of flashing the login screen at a returning user.
  bool get isRestoring;

  bool get isSignedIn => currentUser != null;

  /// Only IT staff and admins can assign work or move a request's status.
  ///
  /// The server enforces this too. This copy exists so the UI can hide controls
  /// that would only fail — it is a courtesy, never the check that matters.
  bool get canManageRequests => currentUser?.role.isSupportStaff ?? false;

  /// Turns a token saved on this device back into a session, if it is still
  /// valid. Returns `Ok(null)` when there is nothing to restore.
  Future<Result<User?>> restore();

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
