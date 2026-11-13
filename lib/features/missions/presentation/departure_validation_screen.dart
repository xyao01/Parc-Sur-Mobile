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

/// Mob-C06 · Validation du départ: records the departure check (`enregistrer_controle`, type `depart`),
/// or blocks the departure (no backend yet: see README).
class DepartureValidationScreen extends StatelessWidget {
  const DepartureValidationScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context) =>
      MissionLoader(missionId: missionId, builder: (context, m) => _Validation(mission: m));
}

enum _View { ready, block, blocked }

class _Validation extends ConsumerStatefulWidget {
  const _Validation({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_Validation> createState() => _ValidationState();
}

class _ValidationState extends ConsumerState<_Validation> {
  late final DepartureDraft _draft = ref.read(departureDraftProvider(widget.mission.id));

  /// Client id of this submission: a retry after a network error is not recorded twice.
  final String _submissionId = uuidV4();
  _View _view = _View.ready;
  bool _confirmed = false;
  bool _busy = false;
  String? _error;
  int? _problem;
  bool _showProblemError = false;
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    if (!_confirmed || _busy) return;
    final km = _draft.odometerKm;
    if (km == null) {
      setState(() => _error = 'Indiquez le kilométrage au compteur.');
      return;
    }
    final id = widget.mission.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Kept on the phone without network, sent as soon as it is back (l2-mob-04).
      await ref.read(controlSubmitterProvider).submit(ControlEntry(
            id: _submissionId,
            missionId: id,
            type: 'depart',
            odometerKm: km,
            fuel: MissionFlowConfig.fuelLevels[_draft.fuel]!,
            points: _draft.points,
            enteredAt: ref.read(clockProvider)(),
          ));
      ref.invalidate(missionsProvider);
      ref.invalidate(departureDraftProvider(id));
      if (mounted) context.go(Routes.inProgress(id));
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Le contrôle n’a pas pu être enregistré. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final problem = _problem;
    if (problem == null) {
      setState(() => _showProblemError = true);
      return;
    }
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(missionsGatewayProvider).reportIncident(
            missionId: widget.mission.id,
            kind: MissionFlowConfig.blockingProblems[problem],
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            blocksDeparture: true,
          );
      if (mounted) setState(() => _view = _View.blocked);
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Le signalement n’a pas pu être envoyé. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final (body, footer) = switch (_view) {
      _View.ready => _readyView(),
      _View.block => _blockView(),
      _View.blocked => _blockedView(),
    };
    return JourneyScaffold(
      offlineBanner: true,
      header: JourneyHeader(
        title: 'Validation du départ',
        subtitle: '${m.number} · ${stepLabel(6)}',
        backLabel: 'Retour à la préparation',
        onBack: () => journeyBack(context),
      ),
      bodyPadding: EdgeInsets.fromLTRB(20, _view == _View.blocked ? 32 : 18, 20, 18),
      body: body,
      footer: footer,
    );
  }

  (Widget, List<Widget>) _readyView() {
    final anomalies = _draft.anomalies;
    final km = _draft.odometerKm;
    return (
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRows(rows: [
            ('Kilométrage', km == null ? '—' : '${FrenchDates.km(km)} km', color: null, size: 14),
            ('Carburant', _draft.fuel, color: null, size: 14),
            (
              'Vérification du véhicule',
              anomalies.isEmpty
                  ? 'Conformes'
                  : '${anomalies.length} anomalie${anomalies.length > 1 ? 's' : ''} : ${anomalies.join(', ')}',
              color: anomalies.isEmpty ? ParcColors.success : ParcColors.danger,
              size: 14,
            ),
            // Photos are not wired yet (see README).
            ('Photos', 'Aucune', color: null, size: 14),
          ]),
          const SizedBox(height: 14),
          ConfirmBox(
            text: 'Je confirme que le véhicule est prêt à partir et que les informations saisies sont exactes.',
            checked: _confirmed,
            onTap: () => setState(() => _confirmed = !_confirmed),
          ),
          const SizedBox(height: 14),
          const InfoNote("L'heure de départ et le kilométrage seront enregistrés à la validation."),
          if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      [
        _confirmed
            ? JourneyActionButton(label: 'Valider et démarrer la mission', busy: _busy, onPressed: _validate)
            : JourneyActionButton(label: 'Cochez la confirmation pour continuer', ready: false, onPressed: () {}),
        DangerSoftButton(
          label: 'Un problème : bloquer le départ',
          onPressed: () => ref.read(featuresProvider).blockDeparture
              ? setState(() {
                  _view = _View.block;
                  _error = null;
                })
              : openMaintenance(context, 'Bloquer le départ'),
        ),
      ],
    );
  }

  (Widget, List<Widget>) _blockView() {
    final ready = _problem != null;
    return (
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ParcColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParcIcon(ParcIcons.warning, size: 20, color: ParcColors.dangerStrong),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le départ sera bloqué. Le gestionnaire est averti et pourra affecter un autre véhicule.',
                    style: parcText(13, weight: 600, color: ParcColors.dangerStrong, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const FieldCaption('Nature du problème', suffix: '(obligatoire)', suffixColor: ParcColors.danger),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, label) in MissionFlowConfig.blockingProblems.indexed)
                PillChoice(
                  label: label,
                  selected: _problem == i,
                  onTap: () => setState(() {
                    _problem = i;
                    _showProblemError = false;
                  }),
                ),
            ],
          ),
          if (_showProblemError && !ready) ...[const SizedBox(height: 8), const FieldError('Choisissez la nature du problème.')],
          const SizedBox(height: 14),
          const FieldCaption('Description'),
          const SizedBox(height: 6),
          ParcTextField(
            controller: _description,
            height: null,
            maxLines: 4,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            hintText: 'Décrivez le problème constaté…',
          ),
          const SizedBox(height: 14),
          const PhotoStrip(addLabel: 'Ajouter une photo du problème'),
          if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      [
        JourneyActionButton(label: 'Bloquer le départ et signaler', danger: true, ready: ready, busy: _busy, onPressed: _block),
        ParcOutlinedButton(
          label: 'Annuler',
          height: 48,
          onPressed: () => setState(() {
            _view = _View.ready;
            _showProblemError = false;
            _error = null;
          }),
        ),
      ],
    );
  }

  (Widget, List<Widget>) _blockedView() {
    final problem = MissionFlowConfig.blockingProblems[_problem!];
    return (
      ResultView(
        icon: ParcIcons.blocked,
        iconBg: ParcColors.dangerSoft,
        iconColor: ParcColors.danger,
        iconSize: 40,
        title: 'Départ bloqué',
        message: Text(
          'Incident « $problem » transmis au gestionnaire. Vous serez notifié dès qu\'un véhicule de remplacement est affecté.',
          textAlign: TextAlign.center,
          style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
        ),
      ),
      [
        ParcPrimaryButton(
          label: "Retour à l'accueil",
          onPressed: () {
            ref.invalidate(missionsProvider);
            context.go(Routes.missions);
          },
        ),
      ],
    );
  }
}
