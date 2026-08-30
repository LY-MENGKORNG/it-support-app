import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/services/api/api_exception.dart';
import 'package:app/ui/auth/view_models/login_viewmodel.dart';
import 'package:app/ui/auth/widgets/login_screen.dart';
import 'package:app/ui/core/themes/theme.dart';

import '../../fakes/repositories/fake_session_repository.dart';

void main() {
  group('LoginScreen', () {
    late FakeSessionRepository session;
    late LoginViewModel viewModel;

    setUp(() {
      // Nobody signed in: this screen only ever exists in that state.
      session = FakeSessionRepository(user: null);
      viewModel = LoginViewModel(sessionRepository: session);
    });

    tearDown(() => viewModel.dispose());

    Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: LoginScreen(viewModel: viewModel),
      ),
    );

    Future<void> fillIn(
      WidgetTester tester, {
      required String email,
      required String password,
    }) async {
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.enterText(find.byType(TextFormField).last, password);
    }

    testWidgets('signs in with the credentials that were typed', (
      tester,
    ) async {
      await pumpScreen(tester);
      await fillIn(
        tester,
        email: 'bopha.lim@example.com',
        password: 'password-123',
      );

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(session.isSignedIn, isTrue);
    });

    // The form must not fire a request it already knows the server will
    // reject — and the user should be told which field is at fault.
    testWidgets('will not submit an incomplete form', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your work email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(session.isSignedIn, isFalse);
    });

    testWidgets('rejects an address that is not one', (tester) async {
      await pumpScreen(tester);
      await fillIn(tester, email: 'bopha.lim', password: 'password-123');

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your work email address.'), findsOneWidget);
      expect(session.isSignedIn, isFalse);
    });

    // A 401 here means "wrong password", not "your session expired" — the
    // generic message would send the user looking for a problem that is not
    // there.
    testWidgets('a 401 is reported as bad credentials', (tester) async {
      session.signInFailure = const HttpException(401, 'Unauthorized');
      await pumpScreen(tester);
      await fillIn(tester, email: 'bopha.lim@example.com', password: 'nope');

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(session.isSignedIn, isFalse);
    });

    testWidgets('an unreachable server says so instead', (tester) async {
      session.signInFailure = const NetworkException();
      await pumpScreen(tester);
      await fillIn(
        tester,
        email: 'bopha.lim@example.com',
        password: 'password-123',
      );

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cannot reach the server'), findsOneWidget);
    });

    testWidgets('the password is obscured until asked for', (tester) async {
      await pumpScreen(tester);

      EditableText passwordField() =>
          tester.widget<EditableText>(find.byType(EditableText).last);

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show'));
      await tester.pumpAndSettle();

      expect(passwordField().obscureText, isFalse);
    });
  });
}
