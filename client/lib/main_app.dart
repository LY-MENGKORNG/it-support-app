import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/routing/router.dart';
import 'package:app/ui/core/themes/theme.dart';

/// The root widget.
///
/// Stateful because it owns the [GoRouter], which must be built exactly once:
/// building it in `build()` would throw the whole navigation stack away on
/// every rebuild.
///
/// It deliberately owns no repositories — those come from the provider tree
/// above it, which is also what disposes them.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final session = context.read<SessionRepository>();
    _router = router(session);

    // Fire-and-forget: the router parks on the splash until this resolves.
    session.restore();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IT Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // The app is dark-only, so the same theme is handed to both slots rather
      // than letting the system pick an undefined light theme.
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
