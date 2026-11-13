import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/features.dart';
import '../../../core/widgets/maintenance_screen.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/uuid.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../data/control_submitter.dart';
import '../data/missions_gateway.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import '../domain/mission_drafts.dart';
import '../domain/mission_flow_config.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C10 · Clôture de la demande: records the return check (`enregistrer_controle`, type `retour`).
/// The request itself is closed by the fleet manager (`cloturer_mission` is not open to drivers).
class ClosureScreen extends StatelessWidget {
  const ClosureScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) => MissionLoader(missionId: missionId, builder: (context, m) => _Closure(mission: m));
}

class _Closure extends ConsumerStatefulWidget {
  const _Closure({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_Closure> createState() => _ClosureState();
}

class _ClosureState extends ConsumerState<_Closure> {
  late final ReturnDraft _draft = ref.read(returnDraftProvider(widget.mission.id));
  late final TextEditingController _observations = TextEditingController(text: _draft.observations)
    ..addListener(() => _draft.observations = _observations.text);

  /// Client id of this submission: a retry after a network error is not recorded twice.
  final String _submissionId = uuidV4();
  bool _confirmed = false;
  bool _busy = false;
  bool _done = false;

  /// Kept on the phone, not sent yet (no network).
  bool _queued = false;
  String? _error;

  @override
  void dispose() {
    _observations.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmed || _busy) return;
    final km = _draft.odometerKm;
    if (km == null) {
      setState(() => _error = 'Indiquez le kilométrage final à l’étape « Arrivée ».');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Kept on the phone without network, sent as soon as it is back (l2-mob-04).
      final result = await ref.read(controlSubmitterProvider).submit(ControlEntry(
            id: _submissionId,
            missionId: widget.mission.id,
            type: 'retour',
            odometerKm: km,
            fuel: MissionFlowConfig.fuelLevels[_draft.fuel]!,
            points: _draft.points,
            observations: _draft.observationsText,
            enteredAt: _draft.arrivedAt ?? ref.read(clockProvider)(),
          ));
      if (mounted) {
        setState(() {
          _done = true;
          _queued = result == SubmitResult.queued;
        });
      }
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Le contrôle de retour n’a pas pu être enregistré. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _home() {
    final id = widget.mission.id;
    ref.invalidate(missionsProvider);
    ref.invalidate(returnDraftProvider(id));
    context.go(Routes.missions);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final leftAt = m.departureCheck?.at ?? m.departure;
    final leftKm = m.departureCheck?.odometerKm;
    final km = _draft.odometerKm;
    final distance = km != null && leftKm != null ? km - leftKm : null;
    final arrivedAt = _draft.arrivedAt;

    return JourneyScaffold(
      offlineBanner: true,
      header: JourneyHeader(
        title: 'Clôture de la demande',
        subtitle: '${m.number} · ${stepLabel(10)}',
        backLabel: 'Retour au contrôle de fin',
        onBack: () => _done ? _home() : journeyBack(context),
      ),
      bodyPadding: EdgeInsets.fromLTRB(20, _done ? 40 : 18, 20, 18),
      body: _done
          ? ResultView(
              icon: ParcIcons.checkBold,
              iconBg: ParcColors.successBg,
              iconColor: ParcColors.success,
              circle: 96,
              iconSize: 50,
              titleSize: 26,
              topPadding: 40,
              // The prototype says « Demande clôturée »: the manager closes the request (see README).
              title: 'Fin de mission enregistrée',
              message: Text(
                _queued
                    ? 'Enregistrée sur le téléphone : elle sera envoyée dès le retour du réseau.'
                    : 'La mission ${m.number} est terminée. Le gestionnaire du parc clôturera la demande.',
                textAlign: TextAlign.center,
                style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
              ),
              child: WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distance == null ? m.destination : '${m.destination} · ${FrenchDates.km(distance)} km',
                      style: parcText(16, weight: 800),
                    ),
                    const SizedBox(height: 6),
                    Text('${m.vehicle.label} · retour au parc enregistré', style: parcText(13, color: ParcColors.textMuted)),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(m.destination, style: parcText(18, weight: 800))),
                          const StatusChip('Terminée', bg: ParcColors.primarySoft, fg: ParcColors.primary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        [?m.purpose, m.requester].join(' · '),
                        style: parcText(13, color: ParcColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: ParcColors.dividerSoft),
                      const SizedBox(height: 12),
                      DetailsGrid(valueWeight: 800, entries: [
                        ('Départ', FrenchDates.shortDayTime(leftAt), color: null),
                        ('Arrivée', arrivedAt == null ? '—' : FrenchDates.shortDayTime(arrivedAt), color: null),
                        (
                          'Kilométrage',
                          leftKm != null && km != null ? '${FrenchDates.km(leftKm)} → ${FrenchDates.km(km)} km' : '—',
                          color: null,
                        ),
                        ('Distance', distance == null ? '—' : '${FrenchDates.km(distance)} km', color: null),
                        // Departure fuel level is not returned by mes_missions_chauffeur: arrival level only.
                        ('Carburant', _draft.fuel, color: null),
                        (
                          'Dommages',
                          _draft.damage ? (_draft.damageZone ?? 'Signalé') : 'Aucun',
                          color: _draft.damage ? ParcColors.danger : ParcColors.success,
                        ),
                        ('Véhicule', m.vehicle.label, color: null),
                        ('Photos', 'Aucune', color: null),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const FieldCaption('Observations', suffix: '(facultatif)'),
                const SizedBox(height: 6),
                ParcTextField(
                  key: const Key('closure.observations'),
                  controller: _observations,
                  height: null,
                  maxLines: 3,
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  hintText: "Remarques sur la mission, l'état de la route, le véhicule…",
                ),
                const SizedBox(height: 14),
                // l2-mis-02 « dépenses engagées »: not in the prototype; no driver access to the expenses yet.
                WhiteCard(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: ref.watch(featuresProvider).missionExpenses
                          ? () {}
                          : () => openMaintenance(context, 'Dépenses de la mission'),
                      child: SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            Expanded(child: Text('Dépenses engagées (carburant, péage…)', style: parcText(14, weight: 700))),
                            const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ConfirmBox(
                  text: "Je confirme la fin de la mission et l'exactitude des informations ci-dessus.",
                  checked: _confirmed,
                  onTap: () => setState(() => _confirmed = !_confirmed),
                ),
                if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
              ],
            ),
      footer: _done
          ? [ParcPrimaryButton(label: "Retour à l'accueil", onPressed: _home)]
          : [JourneyActionButton(label: 'Clôturer la demande', ready: _confirmed, busy: _busy, onPressed: _submit)],
    );
  }
}
