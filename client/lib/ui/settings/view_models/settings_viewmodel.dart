import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

/// Backs the Settings tab: who you are, and how to sign out.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required this._sessionRepository}) {
    signOut = Command0(_signOut);

    // The screen shows the current user, so it has to rebuild when the session
    // changes — including when another screen signs out.
    _sessionRepository.addListener(notifyListeners);
  }

  final SessionRepository _sessionRepository;

  late final Command0<void> signOut;

  User? get currentUser => _sessionRepository.currentUser;

  Future<Result<void>> _signOut() => _sessionRepository.signOut();

  @override
  void dispose() {
    _sessionRepository.removeListener(notifyListeners);
    signOut.dispose();
    super.dispose();
  }
}
