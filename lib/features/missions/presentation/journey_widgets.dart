import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/features.dart';
import '../../../core/widgets/maintenance_screen.dart';

import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../domain/mission_flow_config.dart';

/// Pieces shared by the driver journey screens Mob-C01…C10 (values from the prototype).

String stepLabel(int step) => 'Étape $step sur ${MissionFlowConfig.totalSteps}';

/// Blue header with back button, title and subtitle (C02…C10).
class JourneyHeader extends StatelessWidget {
  const JourneyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.backLabel = 'Retour',
    this.bottom,
    this.bottomPadding = 18,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final String backLabel;
  final Widget? bottom;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.primary,
      padding: EdgeInsets.fromLTRB(20, 20 + top, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ParcHeaderBackButton(
                semanticLabel: backLabel,
                onPressed: onBack,
                icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(title, style: parcText(18, weight: 800, color: ParcColors.surface))),
                    Text(subtitle, style: parcText(12, color: ParcColors.onPrimaryMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ],
      ),
    );
  }
}

/// Screen body: scrolling content and a white footer with the actions.
class JourneyScaffold extends StatelessWidget {
  const JourneyScaffold({super.key, required this.header, required this.body, this.footer, this.bodyPadding});

  final Widget header;
  final Widget body;
  final List<Widget>? footer;
  final EdgeInsets? bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(
              padding: bodyPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: body,
            ),
          ),
          if (footer != null) JourneyFooter(children: footer!),
        ],
      ),
    );
  }
}

class JourneyFooter extends StatelessWidget {
  const JourneyFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: ParcColors.surface,
        border: Border(top: BorderSide(color: ParcColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 10), c],
        ],
      ),
    );
  }
}

/// « MISSION DU JOUR », « VÉHICULE »…
class SectionCaps extends StatelessWidget {
  const SectionCaps(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: parcText(13, weight: 800, color: ParcColors.textMuted, letterSpacing: 0.5)),
      );
}

class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.border = ParcColors.divider,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color border;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ParcColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// Label / value rows separated by thin lines (C02, C06 recap).
class InfoRows extends StatelessWidget {
  const InfoRows({super.key, required this.rows});

  final List<(String, String, {Color? color, double size})> rows;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: ParcColors.dividerSoft)) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(flex: 2, child: Text(r.$1, style: parcText(13, weight: 600, color: ParcColors.textMuted))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.right,
                      style: parcText(r.size, weight: 800, color: r.color ?? ParcColors.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Two-column label / value grid (C03, C10).
class DetailsGrid extends StatelessWidget {
  const DetailsGrid({super.key, required this.entries, this.valueWeight = 700});

  final List<(String, String, {Color? color})> entries;
  final int valueWeight;

  @override
  Widget build(BuildContext context) {
    Widget cell((String, String, {Color? color}) e) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.$1, style: parcText(13, weight: 600, color: ParcColors.textMuted)),
            const SizedBox(height: 2),
            Text(e.$2, style: parcText(13, weight: valueWeight, color: e.color ?? ParcColors.text)),
          ],
        );
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cell(entries[i])),
              const SizedBox(width: 12),
              Expanded(child: i + 1 < entries.length ? cell(entries[i + 1]) : const SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

/// White tile with a small label and a big value (C07, C08).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.valueSize = 20});

  final String label;
  final String value;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: parcText(valueSize, weight: 800)),
        ],
      ),
    );
  }
}

/// Grid of [StatTile]s, two per row.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 10),
                Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bold field caption, with an optional muted suffix (« (facultatif) »).
class FieldCaption extends StatelessWidget {
  const FieldCaption(this.text, {super.key, this.suffix, this.suffixColor = ParcColors.textMuted});

  final String text;
  final String? suffix;
  final Color suffixColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(text: text, style: parcText(14, weight: 800)),
      if (suffix != null) TextSpan(text: ' $suffix', style: parcText(14, weight: 600, color: suffixColor)),
    ]));
  }
}

/// Big odometer input with « km » unit.
class OdometerInput extends StatelessWidget {
  const OdometerInput({super.key, required this.fieldKey, required this.controller, required this.onChanged, this.hint});

  final Key fieldKey;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: ParcColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ParcColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                  onChanged: (_) => onChanged(),
                  style: parcText(24, weight: 800),
                  decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                ),
              ),
              Text('km', style: parcText(14, weight: 700, color: ParcColors.textMuted)),
            ],
          ),
        ),
        if (hint != null) ...[const SizedBox(height: 6), hint!],
      ],
    );
  }
}

int? parseKm(String text) => int.tryParse(text.replaceAll(RegExp(r'\s'), ''));

/// Green / red helper under an odometer input.
class KmHint extends StatelessWidget {
  const KmHint(this.text, {super.key, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: parcText(12, weight: 600, color: ok ? ParcColors.success : ParcColors.danger));
}

/// 1/4 · 1/2 · 3/4 · Plein.
class FuelSelector extends StatelessWidget {
  const FuelSelector({super.key, required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, level) in MissionFlowConfig.fuelLevels.keys.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              selected: selected == level,
              inMutuallyExclusiveGroup: true,
              child: Material(
                color: selected == level ? ParcColors.primary : ParcColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: selected == level ? ParcColors.primary : ParcColors.inputBorder, width: 1.5),
                ),
                child: InkWell(
                  onTap: () => onChanged(level),
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 46,
                    child: Center(
                      child: Text(
                        level,
                        style: parcText(14, weight: 800, color: selected == level ? ParcColors.surface : ParcColors.text),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Green tick box (checklists).
class TickBox extends StatelessWidget {
  const TickBox({super.key, required this.checked, this.size = 24, this.radius = 7, this.iconSize = 14});

  final bool checked;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? ParcColors.success : ParcColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: checked ? ParcColors.success : ParcColors.checkboxBorder, width: 1.5),
      ),
      alignment: Alignment.center,
      child: ParcIcon(ParcIcons.check, size: iconSize, color: ParcColors.surface),
    );
  }
}

/// Checklist line, with an optional hint under the label (C05).
class ChecklistItem extends StatelessWidget {
  const ChecklistItem({super.key, required this.label, this.hint, required this.checked, required this.onTap});

  final String label;
  final String? hint;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: checked,
      child: Material(
        color: ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ParcColors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hint == null ? 46 : 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: hint == null ? 0 : 6),
              child: Row(
                children: [
                  TickBox(checked: checked),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: parcText(14, weight: hint == null ? 600 : 700)),
                        if (hint != null) Text(hint!, style: parcText(12, color: ParcColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Je confirme… » box (C06, C10).
class ConfirmBox extends StatelessWidget {
  const ConfirmBox({super.key, required this.text, required this.checked, required this.onTap});

  final String text;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: checked,
      child: Material(
        color: checked ? ParcColors.successBg : ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: checked ? ParcColors.success : ParcColors.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                TickBox(checked: checked, size: 26, radius: 8, iconSize: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: parcText(14, weight: 700, height: 1.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded pill choice (problem kinds, incident kinds, damage zones).
class PillChoice extends StatelessWidget {
  const PillChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = ParcColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? selectedColor : ParcColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? selectedColor : ParcColors.inputBorder, width: 1.5)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(label, style: parcText(14, weight: 700, color: selected ? ParcColors.surface : ParcColors.text)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-option segmented control (C04 on the blue header, C09 on grey).
class SegmentedChoice extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.selectedColors,
    this.onDark = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Text colour of the selected option, per option.
  final List<Color> selectedColors;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onDark ? ParcColors.headerChip : ParcColors.dividerSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == i,
                child: Material(
                  color: selected == i ? ParcColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          label,
                          style: parcText(
                            14,
                            weight: 800,
                            color: selected == i
                                ? selectedColors[i]
                                : (onDark ? ParcColors.surface : ParcColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Footer action: primary (blue) or danger (red); greyed while not [ready]
/// (still tappable, so the screen can explain what is missing).
class JourneyActionButton extends StatelessWidget {
  const JourneyActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.ready = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;
  final bool ready;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bg = !ready ? ParcColors.dividerSoft : (danger ? ParcColors.danger : ParcColors.primary);
    final fg = ready ? ParcColors.surface : ParcColors.textMuted;
    return Semantics(
      button: true,
      enabled: ready && !busy,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 54,
            child: Center(child: Text(label, textAlign: TextAlign.center, style: parcText(16, weight: 800, color: fg))),
          ),
        ),
      ),
    );
  }
}

/// Light red outlined button (« Refuser », « Signaler un incident », « bloquer le départ »).
class DangerSoftButton extends StatelessWidget {
  const DangerSoftButton({super.key, required this.label, required this.onPressed, this.icon = true, this.height = 48});

  final String label;
  final VoidCallback onPressed;
  final bool icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: ParcColors.dangerBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ParcColors.dangerBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon) ...[const ParcIcon(ParcIcons.warning, size: 18, color: ParcColors.danger), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: parcText(15, weight: 800, color: ParcColors.danger))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Blue info note (« Le gestionnaire recevra votre motif… »).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ParcIcon(ParcIcons.info, size: 18, color: ParcColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: parcText(12, color: ParcColors.textSecondary))),
        ],
      ),
    );
  }
}

/// Red validation message under a field (« Choisissez la nature du problème. »).
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Text(text, style: parcText(13, weight: 700, color: ParcColors.danger)),
      );
}

/// Centred result: round icon, title, text (C04, C06, C10).
class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    this.circle = 84,
    this.iconSize = 44,
    this.titleSize = 24,
    this.topPadding = 32,
    this.child,
  });

  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget message;
  final double circle;
  final double iconSize;
  final double titleSize;
  final double topPadding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding - 18),
      child: Column(
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: ParcIcon(icon, size: iconSize, color: iconColor),
          ),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: parcText(titleSize, weight: 800))),
          const SizedBox(height: 16),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: message),
          if (child != null) ...[const SizedBox(height: 16), child!],
        ],
      ),
    );
  }
}

/// Opens « Page en maintenance » while the view behind a button has no backend ([Features]).
void _maintenanceUnless(BuildContext context, bool Function(Features) enabled, String feature) {
  if (!enabled(ProviderScope.containerOf(context).read(featuresProvider))) openMaintenance(context, feature);
}

/// Grey photo placeholders and the dashed « Ajouter une photo » button.
/// Camera capture is not wired yet (see README): « Page en maintenance ».
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, this.labels = const [], this.addLabel = 'Ajouter une photo'});

  final List<String> labels;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in labels)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: ParcColors.photoPlaceholder, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(l, style: parcText(11, weight: 700, color: ParcColors.textSecondary)),
          ),
        Semantics(
          button: true,
          label: addLabel,
          excludeSemantics: true,
          child: CustomPaint(
            foregroundPainter: const DashedBorderPainter(color: ParcColors.dashed),
            child: Material(
              color: ParcColors.surface,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _maintenanceUnless(context, (f) => f.photos, 'Photos'),
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(child: ParcIcon(ParcIcons.plus, size: 24, color: ParcColors.primary)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Initials in a circle (requester).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 44, this.fontSize = 14});

  final String name;
  final double size;
  final double fontSize;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: ParcColors.dividerSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initialsOf(name), style: parcText(fontSize, weight: 800)),
    );
  }
}

/// Square soft-blue phone button. Calls are not wired yet (see README).
class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: ParcColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _maintenanceUnless(context, (f) => f.phoneCalls, 'Appel téléphonique'),
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(child: ParcIcon(ParcIcons.phone, size: 20, color: ParcColors.primary)),
          ),
        ),
      ),
    );
  }
}

/// Small coloured badge (« À répondre », « Disponible », « Terminée »).
class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {super.key, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: parcText(12, weight: 800, color: fg)),
    );
  }
}
