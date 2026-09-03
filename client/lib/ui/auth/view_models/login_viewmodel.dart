import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

typedef Credentials = ({String email, String password});

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
