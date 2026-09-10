import 'package:app/routing/route_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

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

import 'route.dart';

/// The app's routes, and the guard that decides which of them you may see.
GoRouter router(SessionRepository sessionRepository) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: sessionRepository,
  redirect: (context, state) => guard(state, sessionRepository),
  routes: [
    GoRoute(
      path: Routes.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.login,
      name: RouteNames.login,
      builder: (context, state) => owned(
        () => LoginViewModel(sessionRepository: sessionRepository),
        (viewModel) => LoginScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.newRequest,
      name: RouteNames.newRequest,
      builder: (context, state) => owned(
        () => CreateRequestViewModel(
          requestRepository: Get.find(),
          categoryRepository: Get.find(),
          sessionRepository: sessionRepository,
        ),
        (viewModel) => CreateRequestScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: '${Routes.requests}/:id',
      name: RouteNames.requestDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const InvalidRequestScreen();

        return owned(
          () => RequestDetailViewModel(
            requestRepository: Get.find(),
            userRepository: Get.find(),
            categoryRepository: Get.find(),
            sessionRepository: sessionRepository,
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
              builder: (context, state) => owned(
                () => RequestListViewModel(
                  requestRepository: Get.find(),
                  categoryRepository: Get.find(),
                  sessionRepository: sessionRepository,
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
              builder: (context, state) => owned(
                () => UserListViewModel(userRepository: Get.find()),
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
              builder: (context, state) => owned(
                () => SettingsViewModel(sessionRepository: sessionRepository),
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
