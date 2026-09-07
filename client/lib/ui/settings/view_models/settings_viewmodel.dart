import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/safe_notifier.dart';

class SettingsViewModel extends ChangeNotifier with SafeNotifier {
  SettingsViewModel({required this._sessionRepository}) {
    signOut = Command0(_signOut);

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
