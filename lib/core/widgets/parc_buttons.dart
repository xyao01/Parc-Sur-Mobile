import 'package:flutter/material.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';

/// Filled primary button (« Se connecter », « Valider le départ », …).
class ParcPrimaryButton extends StatelessWidget {
  const ParcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
    this.radius = 14,
    this.fontSize = 16,
    this.weight = 800,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final double fontSize;
  final int weight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ParcColors.primary,
          foregroundColor: ParcColors.surface,
          disabledBackgroundColor: ParcColors.primary,
          disabledForegroundColor: ParcColors.surface,
          overlayColor: ParcColors.primaryPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: parcText(fontSize, weight: weight, color: ParcColors.surface),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// White outlined button (« Utiliser l'empreinte digitale », « Annuler »).
class ParcOutlinedButton extends StatelessWidget {
  const ParcOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.height = 54,
    this.radius = 14,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: ParcColors.surface,
          foregroundColor: ParcColors.text,
          side: const BorderSide(color: ParcColors.inputBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: parcText(fontSize, weight: 700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Square 44×44 back button on a coloured header.
class ParcHeaderBackButton extends StatelessWidget {
  const ParcHeaderBackButton({super.key, required this.semanticLabel, required this.onPressed, required this.icon});

  final String semanticLabel;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: ParcColors.headerChip,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
        ),
      ),
    );
  }
}
