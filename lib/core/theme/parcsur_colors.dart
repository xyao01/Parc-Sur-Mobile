import 'package:flutter/painting.dart';

/// ParcSûr colour tokens, taken verbatim from the Claude Design prototype
/// (canvas « Gestion Parc Auto – Noms et logos », page Maquettes, Mob-*).
abstract final class ParcColors {
  // Brand
  static const navy = Color(0xFF0B1F3A); // ink + dark headers
  static const primary = Color(0xFF0A3D7A);
  static const primaryPressed = Color(0xFF072B57);
  static const accent = Color(0xFFF08A24);

  // Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const primarySoft = Color(0xFFE8F1FB);
  static const headerChip = Color(0xFF16335C);
  static const stepInactive = Color(0xFF2C5A93);
  static const photoPlaceholder = Color(0xFFDCE6F2);

  // Borders
  static const inputBorder = Color(0xFFD5DEE8);
  static const divider = Color(0xFFE2E8F0);
  static const dividerSoft = Color(0xFFEEF2F6);
  static const dashed = Color(0xFF93AFD3);
  static const checkboxBorder = Color(0xFF93A3B8);

  // Text
  static const text = navy;
  static const textMuted = Color(0xFF5B6B7F);
  static const textSecondary = Color(0xFF34445A);
  static const onDarkMuted = Color(0xFFB8C4D6);
  static const onPrimaryMuted = Color(0xFFC9D8EC);

  // Status
  static const success = Color(0xFF1F6B45);
  static const danger = Color(0xFFB42318);
  static const dangerBg = Color(0xFFFEF3F2);
  static const warningBg = Color(0xFFFFF8EB);
  static const warningText = Color(0xFF7A4209);

  static const scrim = Color(0x8C0B1F3A); // rgba(11,31,58,.55)
  static const sheetShadow = Color(0x3D0B1F3A); // rgba(11,31,58,.24)
}
