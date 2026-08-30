import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

/// What the login form hands to [LoginViewModel.signIn].
///
/// A record rather than a class: a transient bundle of two text fields, with no
/// identity and no behaviour.
typedef Credentials = ({String email, String password});

/// Backs the login screen.
///
/// It owns exactly one action. The email and password *values* stay in the
/// widget's controllers — a view model that mirrored every keystroke would
/// rebuild the screen on each one, and would mean holding a plaintext password
/// in two places instead of one.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this._sessionRepository}) {
    signIn = Command1(_signIn);
  }

  final SessionRepository _sessionRepository;

  late final Command1<void, Credentials> signIn;

  Future<Result<void>> _signIn(Credentials credentials) => _sessionRepository
      .signIn(email: credentials.email.trim(), password: credentials.password);

  @override
  void dispose() {
    signIn.dispose();
    super.dispose();
  }
}
