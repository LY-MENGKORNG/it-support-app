import 'package:app/config/di/dependencies.dart';
import 'package:flutter/material.dart';

import 'package:app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDeps();
  runApp(const App());
}
