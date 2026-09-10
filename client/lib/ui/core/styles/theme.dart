import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const radius = BorderRadius.zero;
  static const _sharp = RoundedRectangleBorder(borderRadius: radius);

  static const _background = Color(0xFF0B0D10);
  static const _surface = Color(0xFF131619);
  static const _surfaceHigh = Color(0xFF1B1F24);
  static const _border = Color(0xFF2A3038);
  static const _accent = Color(0xFFFFFFFF);
  static const _onAccent = Color(0xFF05070A);
  static const _onSurface = Color(0xFFE6E9EE);
  static const _muted = Color(0xFF8B95A3);
  static const _danger = Color(0xFFEF4444);

  static const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _accent,
    onPrimary: _onAccent,
    secondary: _accent,
    onSecondary: _onAccent,
    surface: _surface,
    onSurface: _onSurface,
    surfaceContainerLowest: _background,
    surfaceContainerLow: _surface,
    surfaceContainer: _surfaceHigh,
    surfaceContainerHigh: _surfaceHigh,
    surfaceContainerHighest: Color(0xFF232830),
    onSurfaceVariant: _muted,
    outline: _border,
    outlineVariant: Color(0xFF1F242B),
    error: _danger,
    onError: _onAccent,
  );

  static OutlineInputBorder _sharpBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData dark() {
    final base = ThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: _border)),
      ),
      cardTheme: const CardThemeData(
        color: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _sharp,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        shape: _sharp,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: _sharpBorder(_border),
        enabledBorder: _sharpBorder(_border),
        focusedBorder: _sharpBorder(_accent, width: 1.5),
        errorBorder: _sharpBorder(_danger),
        focusedErrorBorder: _sharpBorder(_danger, width: 1.5),
        hintStyle: const TextStyle(color: _muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _sharp,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _sharp,
          side: const BorderSide(color: _border),
          foregroundColor: _onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: _sharp),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: _sharp),
      ),
      chipTheme: ChipThemeData(
        shape: _sharp,
        side: const BorderSide(color: _border),
        backgroundColor: _surfaceHigh,
        selectedColor: _accent,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // A selected chip is filled with the white accent, so its label has to
        // invert or it vanishes. Note this has to be a [WidgetStateColor] on
        // the `color` field: Chip flattens a [WidgetStateTextStyle] here and
        // only ever state-resolves the colour inside the style.
        labelStyle: (base.textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? _onAccent : _onSurface,
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: _sharp,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: _sharp,
        showDragHandle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _surfaceHigh,
        contentTextStyle: TextStyle(color: _onSurface),
        behavior: SnackBarBehavior.floating,
        shape: _sharp,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: _surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: _sharp,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _accent.withValues(alpha: 0.18),
        indicatorShape: _sharp,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? _accent : _muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? _accent : _muted,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: _sharp,
        backgroundColor: _accent,
        foregroundColor: _onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
        linearMinHeight: 2,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: _sharpBorder(_border),
          enabledBorder: _sharpBorder(_border),
          focusedBorder: _sharpBorder(_accent, width: 1.5),
        ),
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(_surfaceHigh),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(_sharp),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _onSurface,
        displayColor: _onSurface,
      ),
    );
  }
}
