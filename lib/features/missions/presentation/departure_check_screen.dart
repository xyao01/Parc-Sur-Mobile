import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../data/missions_providers.dart';
import '../domain/departure_check_config.dart';
import '../domain/mission.dart';

/// Mobile · Contrôle de départ (chauffeur).
class DepartureCheckScreen extends ConsumerStatefulWidget {
  const DepartureCheckScreen({super.key, required this.missionId});

  final String missionId;

  @override
  ConsumerState<DepartureCheckScreen> createState() => _DepartureCheckScreenState();
}

class _DepartureCheckScreenState extends ConsumerState<DepartureCheckScreen> {
  final _odometer = TextEditingController();
  String _fuel = DepartureCheckConfig.defaultFuelLevel;
  final Set<int> _checked = {};
  final List<String> _photos = [];

  @override
  void dispose() {
    _odometer.dispose();
    super.dispose();
  }

  int? get _km => int.tryParse(_odometer.text.replaceAll(RegExp(r'\s'), ''));

  void _back() => context.canPop() ? context.pop() : context.go('/missions');

  @override
  Widget build(BuildContext context) {
    final mission = ref.watch(missionByIdProvider(widget.missionId));
    final offline = ref.watch(isOfflineProvider);
    final vehicle = mission?.vehicle;

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          _Header(subtitle: vehicle?.label ?? 'Véhicule à confirmer', onBack: _back),
          if (offline) const _OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OdometerField(controller: _odometer, last: vehicle?.lastOdometer, km: _km, onChanged: () => setState(() {})),
                const SizedBox(height: 16),
                const _Legend('Niveau de carburant'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (i, level) in DepartureCheckConfig.fuelLevels.indexed) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _FuelOption(
                          label: level,
                          selected: _fuel == level,
                          onTap: () => setState(() => _fuel = level),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const _Legend('État du véhicule'),
                const SizedBox(height: 8),
                for (final (i, label) in DepartureCheckConfig.checklist.indexed) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _CheckItem(
                    label: label,
                    checked: _checked.contains(i),
                    onTap: () => setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i)),
                  ),
                ],
                const SizedBox(height: 16),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Photos ', style: parcText(14, weight: 800)),
                  TextSpan(text: '(facultatif)', style: parcText(14, weight: 600, color: ParcColors.textMuted)),
                ])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _photos) _PhotoThumb(label: p),
                    const _AddPhotoButton(),
                  ],
                ),
              ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              color: ParcColors.surface,
              border: Border(top: BorderSide(color: ParcColors.divider)),
            ),
            // Submission is not wired to a backend yet (see README).
            child: ParcPrimaryButton(label: 'Valider le départ', onPressed: () {}),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle, required this.onBack});

  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const step = DepartureCheckConfig.currentStep;
    const total = DepartureCheckConfig.totalSteps;
    return Container(
      color: ParcColors.primary,
      padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ParcHeaderBackButton(
                semanticLabel: 'Retour aux missions',
                onPressed: onBack,
                icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Contrôle de départ', style: parcText(18, weight: 800, color: ParcColors.surface))),
                    Text(subtitle, style: parcText(12, color: ParcColors.onPrimaryMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Étape $step sur $total',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step ? ParcColors.accent : ParcColors.stepInactive,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: ParcColors.warningBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            const ParcIcon(ParcIcons.wifiOff, size: 16, color: ParcColors.warningText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hors connexion : la saisie sera envoyée dès le retour du réseau.',
                style: parcText(12, weight: 600, color: ParcColors.warningText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: parcText(14, weight: 800));
}

class _OdometerField extends StatelessWidget {
  const _OdometerField({required this.controller, required this.last, required this.km, required this.onChanged});

  final TextEditingController controller;
  final OdometerReading? last;
  final int? km;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final last = this.last;
    Widget? hint;
    if (last != null) {
      final ref = '${FrenchDates.km(last.km)} km le ${FrenchDates.dayMonth(last.date)}';
      final low = km != null && km! < last.km;
      hint = Text(
        low ? 'Inférieur au dernier relevé ($ref)' : 'Cohérent avec le dernier relevé ($ref)',
        style: parcText(12, weight: 600, color: low ? ParcColors.danger : ParcColors.success),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kilométrage au compteur', style: parcText(14, weight: 800)),
        const SizedBox(height: 6),
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
                  key: const Key('departure.odometer'),
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
        if (hint != null) ...[const SizedBox(height: 6), hint],
      ],
    );
  }
}

class _FuelOption extends StatelessWidget {
  const _FuelOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('departure.option.$label'),
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? ParcColors.primary : ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? ParcColors.primary : ParcColors.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 46,
            child: Center(
              child: Text(label, style: parcText(14, weight: 800, color: selected ? ParcColors.surface : ParcColors.text)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.label, required this.checked, required this.onTap});

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('departure.option.$label'),
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
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: checked ? ParcColors.success : ParcColors.surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: checked ? ParcColors.success : ParcColors.checkboxBorder, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const ParcIcon(ParcIcons.check, size: 14, color: ParcColors.surface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: parcText(14, weight: 600))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: ParcColors.photoPlaceholder, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(label, style: parcText(11, weight: 700, color: ParcColors.textSecondary)),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ajouter une photo',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: const DashedBorderPainter(color: ParcColors.dashed),
        child: Material(
          color: ParcColors.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            // Camera capture not wired yet (see README).
            onTap: () {},
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
              width: 72,
              height: 72,
              child: Center(child: ParcIcon(ParcIcons.plus, size: 24, color: ParcColors.primary)),
            ),
          ),
        ),
      ),
    );
  }
}
