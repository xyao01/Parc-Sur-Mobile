import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import '../domain/mission_drafts.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C08 · Arrivée à destination. Arrival time and final odometer are sent with the
/// return check at Mob-C10 (`enregistrer_controle` needs the fuel level too).
class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) => MissionLoader(missionId: missionId, builder: (context, m) => _Arrival(mission: m));
}

class _Arrival extends ConsumerStatefulWidget {
  const _Arrival({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends ConsumerState<_Arrival> {
  late final ReturnDraft _draft = ref.read(returnDraftProvider(widget.mission.id))
    ..arrivedAt ??= ref.read(clockProvider)();
  late final _odometer = TextEditingController(text: _draft.odometerKm == null ? '' : FrenchDates.km(_draft.odometerKm!));
  String? _error;

  @override
  void dispose() {
    _odometer.dispose();
    super.dispose();
  }

  DateTime get _leftAt => widget.mission.departureCheck?.at ?? widget.mission.departure;
  int? get _leftKm => widget.mission.departureCheck?.odometerKm;

  Future<void> _pickTime() async {
    final current = _draft.arrivedAt!;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (picked == null || !mounted) return;
    setState(() => _draft.arrivedAt = DateTime(current.year, current.month, current.day, picked.hour, picked.minute));
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final km = parseKm(_odometer.text);
    final leftKm = _leftKm;
    if (km == null) {
      setState(() => _error = 'Indiquez le kilométrage final.');
      return;
    }
    if (leftKm != null && km < leftKm) {
      setState(() => _error = 'Le kilométrage final ne peut pas être inférieur à celui du départ.');
      return;
    }
    _draft.odometerKm = km;
    setState(() => _error = null);
    context.push(Routes.endCheck(widget.mission.id));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final arrivedAt = _draft.arrivedAt!;
    final km = parseKm(_odometer.text);
    final leftKm = _leftKm;
    final distance = km != null && leftKm != null && km >= leftKm ? km - leftKm : null;
    Widget? hint;
    if (km != null && leftKm != null) {
      hint = km >= leftKm
          ? KmHint('Cohérent : ${FrenchDates.km(km - leftKm)} km parcourus depuis le départ (${FrenchDates.km(leftKm)} km)', ok: true)
          : KmHint('Inférieur au kilométrage de départ (${FrenchDates.km(leftKm)} km)', ok: false);
    }
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Arrivée à destination',
        subtitle: '${m.number} · ${stepLabel(8)}',
        backLabel: 'Retour à la mission en cours',
        onBack: () => journeyBack(context),
      ),
      bodyPadding: const EdgeInsets.all(20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: ParcColors.successBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: ParcColors.success, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const ParcIcon(ParcIcons.mapPin, size: 22, color: ParcColors.surface),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vous êtes arrivé à', style: parcText(13, weight: 700, color: ParcColors.success)),
                      Text(m.destination, style: parcText(22, weight: 800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FieldCaption("Heure d'arrivée"),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            label: "Heure d'arrivée",
            value: FrenchDates.time(arrivedAt),
            excludeSemantics: true,
            child: Material(
              color: ParcColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ParcColors.inputBorder, width: 1.5),
              ),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: Text(FrenchDates.time(arrivedAt), style: parcText(24, weight: 800)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enregistrée automatiquement, modifiable si besoin. Départ à ${FrenchDates.time(_leftAt)}.',
            style: parcText(12, weight: 600, color: ParcColors.textMuted),
          ),
          const SizedBox(height: 16),
          const FieldCaption('Kilométrage final'),
          const SizedBox(height: 6),
          OdometerInput(
            fieldKey: const Key('arrival.odometer'),
            controller: _odometer,
            onChanged: () => setState(() {}),
            hint: hint,
          ),
          const SizedBox(height: 16),
          StatGrid(tiles: [
            StatTile(label: 'Distance', value: distance == null ? '—' : '${FrenchDates.km(distance)} km'),
            StatTile(label: 'Durée de trajet', value: FrenchDates.duration(arrivedAt.difference(_leftAt))),
          ]),
        ],
      ),
      footer: [
        if (_error != null) ParcErrorAlert(message: _error!),
        ParcPrimaryButton(label: "Enregistrer l'arrivée", onPressed: _save),
      ],
    );
  }
}
