import 'package:flutter/widgets.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';

/// Error box from the web prototype « Connexion – blocage » (`role="alert"`).
class ParcErrorAlert extends StatelessWidget {
  const ParcErrorAlert({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: ParcColors.dangerBg, borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: parcText(14, weight: 600, color: ParcColors.danger, height: 1.5)),
      ),
    );
  }
}
