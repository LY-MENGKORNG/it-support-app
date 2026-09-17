import 'package:app/ui/core/styles/painting.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppTheme {
  static final colorScheme = ShadColorScheme.fromName(
    'zinc',
    brightness: Brightness.dark,
  );

  static ShadThemeData dark() {
    return ShadThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      radius: Painting.radius,
      textTheme: ShadTextTheme(
        p: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}
