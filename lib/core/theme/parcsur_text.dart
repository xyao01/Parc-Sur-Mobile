import 'package:flutter/painting.dart';

import 'parcsur_colors.dart';

const parcFontFamily = 'Manrope';

/// Manrope text style. The font ships as a single variable file, so the weight
/// is applied both as [FontWeight] and as the `wght` variation axis.
TextStyle parcText(
  double size, {
  int weight = 400,
  Color color = ParcColors.text,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: parcFontFamily,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
