import 'package:flutter/foundation.dart';
import 'package:app/utils/exception.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

typedef Credentials = ({String email, String password});

class LoginViewModel extends ChangeNotifier {
  final SessionRepository _sessionRepository;
  final validator = LoginValidator();

  late final Command1<void, Credentials> signIn;

  LoginViewModel({required this._sessionRepository}) {
    signIn = Command1(_signIn);
  }

  Future<Result<void>> _signIn(Credentials credentials) {
    return _sessionRepository.signIn(
      email: credentials.email.trim(),
      password: credentials.password,
    );
  }

  String messageFor(Exception? exception) => switch (exception) {
    HttpException(:final isUnauthorized) when isUnauthorized =>
      'Incorrect email or password.',
    final Exception error => messageFor(error),
    null => 'Could not sign in.',
  };

  @override
  void dispose() {
    signIn.dispose();
    super.dispose();
  }
}

/// A simple validator for login form fields.
final class LoginValidator {
  String? validateEmail(String value) {
    return switch (value.trim()) {
      '' => 'Enter your work email address.',
      _ when !value.trim().contains('@') => 'Enter a valid email address.',
      _ when !value.trim().endsWith('.com') => 'Enter a valid email address.',
      _ => null,
    };
  }

  String? validatePassword(String value) {
    return switch (value) {
      '' => 'Enter your password.',
      _ when value.length < 6 => 'Password must be at least 6 characters.',
      _ => null,
    };
  }
}
