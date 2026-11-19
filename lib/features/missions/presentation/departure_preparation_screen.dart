import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/french_dates.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import '../domain/mission_drafts.dart';
import '../domain/mission_flow_config.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C05 · Préparation du départ. Entries are kept for Mob-C06, which records them.
class DeparturePreparationScreen extends StatelessWidget {
  const DeparturePreparationScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) =>
      MissionLoader(missionId: missionId, builder: (context, m) => _Preparation(mission: m));
}

class _Preparation extends ConsumerStatefulWidget {
  const _Preparation({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_Preparation> createState() => _PreparationState();
}

class _PreparationState extends ConsumerState<_Preparation> {
  late final DepartureDraft _draft = ref.read(departureDraftProvider(widget.mission.id));
  late final _odometer = TextEditingController(text: _draft.odometerKm == null ? '' : FrenchDates.km(_draft.odometerKm!));
  String? _error;

  @override
  void dispose() {
    _odometer.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    final km = parseKm(_odometer.text);
    if (km == null) {
      setState(() => _error = 'Indiquez le kilométrage au compteur.');
      return;
    }
    final last = widget.mission.vehicle.odometerKm;
    if (last != null && km < last) {
      // Same rule as the database (relevé ≥ dernier relevé), checked before sending (l2-mis-01).
      setState(() => _error = 'Le kilométrage ne peut pas être inférieur au dernier relevé (${FrenchDates.km(last)} km).');
      return;
    }
    _draft.odometerKm = km;
    setState(() => _error = null);
    context.push(Routes.departureValidation(widget.mission.id));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final last = m.vehicle.odometerKm;
    final km = parseKm(_odometer.text);
    Widget? hint;
    if (last != null) {
      // Date of the last reading is not returned by mes_missions_chauffeur (see README).
      final low = km != null && km < last;
      hint = KmHint(
        low ? 'Inférieur au dernier relevé (${FrenchDates.km(last)} km)' : 'Cohérent avec le dernier relevé (${FrenchDates.km(last)} km)',
        ok: !low,
      );
    }
    return JourneyScaffold(
      offlineBanner: true,
      header: JourneyHeader(
        title: 'Préparation du départ',
        subtitle: m.vehicle.label,
        onBack: () => journeyBack(context),
        bottomPadding: 16,
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldCaption('Kilométrage au compteur'),
          const SizedBox(height: 6),
          OdometerInput(
            fieldKey: const Key('preparation.odometer'),
            controller: _odometer,
            onChanged: () => setState(() {}),
            hint: hint,
          ),
          const SizedBox(height: 16),
          const FieldCaption('Niveau de carburant'),
          const SizedBox(height: 8),
          FuelSelector(selected: _draft.fuel, onChanged: (v) => setState(() => _draft.fuel = v)),
          const SizedBox(height: 16),
          const FieldCaption('Vérification du véhicule'),
          const SizedBox(height: 8),
          for (final (i, c) in MissionFlowConfig.departureChecklist.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            ChecklistItem(
              label: c.label,
              hint: c.hint,
              checked: _draft.checked.contains(c.label),
              onTap: () => setState(() => _draft.checked.contains(c.label) ? _draft.checked.remove(c.label) : _draft.checked.add(c.label)),
            ),
          ],
          const SizedBox(height: 16),
          const FieldCaption('Photos du véhicule'),
          const SizedBox(height: 8),
          const PhotoStrip(),
        ],
      ),
      footer: [
        if (_error != null) ParcErrorAlert(message: _error!),
        ParcPrimaryButton(label: 'Continuer vers la validation', onPressed: _continue),
      ],
    );
  }
}
