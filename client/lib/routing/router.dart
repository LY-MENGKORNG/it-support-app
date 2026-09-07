import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/ui/core/ui/home_shell.dart';
import 'package:app/ui/requests/view_models/create_request_viewmodel.dart';
import 'package:app/ui/requests/view_models/request_detail_viewmodel.dart';
import 'package:app/ui/requests/view_models/request_list_viewmodel.dart';
import 'package:app/ui/requests/widgets/create_request_screen.dart';
import 'package:app/ui/requests/widgets/request_detail_screen.dart';
import 'package:app/ui/requests/widgets/request_list_screen.dart';
import 'package:app/ui/auth/view_models/login_viewmodel.dart';
import 'package:app/ui/auth/widgets/login_screen.dart';
import 'package:app/ui/auth/widgets/splash_screen.dart';
import 'package:app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:app/ui/settings/widgets/settings_screen.dart';
import 'package:app/ui/users/view_models/user_list_viewmodel.dart';
import 'package:app/ui/users/widgets/user_list_screen.dart';

import 'routes.dart';

GoRouter router(SessionRepository sessionRepository) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: sessionRepository,
  redirect: (context, state) => _guard(state, sessionRepository),
  routes: [
    GoRoute(
      path: Routes.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.login,
      name: RouteNames.login,
      builder: (context, state) => _owned(
        (context) => LoginViewModel(sessionRepository: context.read()),
        (viewModel) => LoginScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.newRequest,
      name: RouteNames.newRequest,
      builder: (context, state) => _owned(
        (context) => CreateRequestViewModel(
          requestRepository: context.read(),
          categoryRepository: context.read(),
          sessionRepository: context.read(),
        ),
        (viewModel) => CreateRequestScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: '${Routes.requests}/:id',
      name: RouteNames.requestDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const _InvalidRequestScreen();

        return _owned(
          (context) => RequestDetailViewModel(
            requestRepository: context.read(),
            userRepository: context.read(),
            categoryRepository: context.read(),
            sessionRepository: context.read(),
            requestId: id,
            preview: state.extra is Request ? state.extra! as Request : null,
          ),
          (viewModel) => RequestDetailScreen(viewModel: viewModel),
        );
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.requests,
              name: RouteNames.requests,
              builder: (context, state) => _owned(
                (context) => RequestListViewModel(
                  requestRepository: context.read(),
                  categoryRepository: context.read(),
                ),
                (viewModel) => RequestListScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.users,
              name: RouteNames.users,
              builder: (context, state) => _owned(
                (context) => UserListViewModel(userRepository: context.read()),
                (viewModel) => UserListScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              name: RouteNames.settings,
              builder: (context, state) => _owned(
                (context) =>
                    SettingsViewModel(sessionRepository: context.read()),
                (viewModel) => SettingsScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
);

String? _guard(GoRouterState state, SessionRepository session) {
  final location = state.matchedLocation;

  if (session.isRestoring) {
    return location == Routes.splash ? null : Routes.splash;
  }

  if (location == Routes.splash) {
    return session.isSignedIn ? Routes.requests : Routes.login;
  }

  if (!session.isSignedIn && location != Routes.login) {
    return Routes.login;
  }

  if (session.isSignedIn && location == Routes.login) {
    return Routes.requests;
  }

  return null;
}

/// Gives a route's view model an owner.
///
/// Built inline in a `builder`, as these used to be, a view model has none:
/// nothing ever calls its `dispose`, so its commands, debounce timers and — in
/// [SettingsViewModel]'s case — a listener on the shared [SessionRepository]
/// outlive the screen, and a route visited twice leaves two of them behind.
///
/// [ChangeNotifierProvider] gives it a lifetime: [create] runs once per route
/// instance rather than on every rebuild of the builder, and the view model is
/// disposed when the route leaves the tree.
Widget _owned<T extends ChangeNotifier>(
  T Function(BuildContext context) create,
  Widget Function(T viewModel) build,
) => ChangeNotifierProvider<T>(
  create: create,
  child: Builder(builder: (context) => build(context.read<T>())),
);

class _InvalidRequestScreen extends StatelessWidget {
  const _InvalidRequestScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request')),
    body: const Center(child: Text('That request id is not valid.')),
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error?.toString() ?? 'This page does not exist.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.requests),
              child: const Text('Back to requests'),
            ),
          ],
        ),
      ),
    ),
  );
}
