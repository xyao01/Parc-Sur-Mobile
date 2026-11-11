import 'package:flutter/material.dart';

import 'parcsur_colors.dart';
import 'parcsur_text.dart';

ThemeData buildParcSurTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: parcFontFamily,
    scaffoldBackgroundColor: ParcColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ParcColors.primary,
      primary: ParcColors.primary,
      secondary: ParcColors.accent,
      surface: ParcColors.surface,
      error: ParcColors.danger,
    ),
  );
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(cursorColor: ParcColors.primary),
    splashFactory: InkRipple.splashFactory,
  );
}
