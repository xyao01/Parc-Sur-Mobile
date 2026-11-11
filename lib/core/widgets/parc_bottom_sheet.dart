import 'package:flutter/material.dart';

import '../theme/parcsur_colors.dart';
import '../theme/parcsur_text.dart';
import 'parc_buttons.dart';
import 'parc_icon.dart';

/// Modal pattern « Modale sous 600 px (feuille basse) »: sheet anchored at the
/// bottom, max 92 % height, scrolling body, actions always visible and stacked
/// with the primary action on top.
Future<T?> showParcBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String cancelLabel = 'Annuler',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: ParcColors.scrim,
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.92;
      final viewInsets = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _ParcSheet(
            title: title,
            subtitle: subtitle,
            primaryLabel: primaryLabel,
            onPrimary: onPrimary,
            cancelLabel: cancelLabel,
            child: child,
          ),
        ),
      );
    },
  );
}

class _ParcSheet extends StatelessWidget {
  const _ParcSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    required this.cancelLabel,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    return Semantics(
      container: true,
      child: Container(
        decoration: const BoxDecoration(
          color: ParcColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: ParcColors.sheetShadow, blurRadius: 48, offset: Offset(0, 24))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(title, style: parcText(18, weight: 800))),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: parcText(14, color: ParcColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Semantics(
                      container: true,
                      button: true,
                      label: 'Fermer',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: close,
                        borderRadius: BorderRadius.circular(10),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(child: ParcIcon(ParcIcons.close, size: 20, color: ParcColors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: child,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: ParcColors.dividerSoft))),
              child: Column(
                children: [
                  ParcPrimaryButton(label: primaryLabel, onPressed: onPrimary, height: 46, radius: 10, fontSize: 14, weight: 700),
                  const SizedBox(height: 12),
                  ParcOutlinedButton(label: cancelLabel, onPressed: close, height: 46, radius: 10, fontSize: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
