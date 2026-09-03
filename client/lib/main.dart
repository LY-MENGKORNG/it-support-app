import 'package:app/config/di/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: remoteProviders, child: const App()));
}
