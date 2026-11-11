import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';

/// Logo « Route sécurisée » (piste A retenue) – shield + road with centre line.
class ParcSurMark extends StatelessWidget {
  const ParcSurMark({super.key, required this.size});

  final double size;

  static const _svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
      '<path d="M50 10 L83 23 V48 C83 68 69 81 50 90 C31 81 17 68 17 48 V23 Z" fill="#FFFFFF"/>'
      '<path d="M38 82 L47 34 L53 34 L62 82 Z" fill="#0A3D7A"/>'
      '<path d="M50 74 V79 M50 58 V64 M50 44 V48" fill="none" stroke="#F08A24" stroke-width="3.5" stroke-linecap="round"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: SvgPicture.string(_svg, width: size, height: size));
  }
}

/// Wordmark « Parc**Sûr** » on dark backgrounds.
class ParcSurWordmark extends StatelessWidget {
  const ParcSurWordmark({super.key, required this.fontSize, this.letterSpacing});

  final double fontSize;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final style = parcText(fontSize, weight: 800, color: ParcColors.surface, letterSpacing: letterSpacing);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Parc', style: style),
        TextSpan(text: 'Sûr', style: style.copyWith(color: ParcColors.accent)),
      ]),
      semanticsLabel: 'ParcSûr',
    );
  }
}
