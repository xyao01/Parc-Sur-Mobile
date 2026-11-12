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
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../data/missions_gateway.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import '../domain/mission_flow_config.dart';
import 'journey_widgets.dart';
import 'mission_loader.dart';

/// Mob-C07 · Mission en cours (after the departure check).
class MissionInProgressScreen extends ConsumerWidget {
  const MissionInProgressScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return MissionLoader(
      missionId: missionId,
      builder: (context, m) {
        final leftAt = m.departureCheck?.at ?? m.departure;
        final leftKm = m.departureCheck?.odometerKm;
        return Scaffold(
          backgroundColor: ParcColors.background,
          body: Column(
            children: [
              _Header(mission: m),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Progress(mission: m, leftAt: leftAt, now: now),
                      const SizedBox(height: 14),
                      StatGrid(tiles: [
                        StatTile(label: 'Heure de départ', value: FrenchDates.time(leftAt)),
                        StatTile(label: 'Durée écoulée', value: FrenchDates.duration(now.difference(leftAt))),
                        StatTile(label: 'Km au départ', value: leftKm == null ? '—' : FrenchDates.km(leftKm)),
                        StatTile(label: 'Véhicule', value: m.vehicle.label, valueSize: 14),
                      ]),
                      const SizedBox(height: 14),
                      WhiteCard(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            InitialsAvatar(m.requester, size: 40, fontSize: 13),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.requester, style: parcText(14, weight: 800)),
                                  Text('Demandeur · ${m.passengers} passager${m.passengers > 1 ? 's' : ''}',
                                      style: parcText(12, color: ParcColors.textMuted)),
                                ],
                              ),
                            ),
                            if (m.requesterPhone != null) const CallButton(label: 'Appeler le demandeur'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              JourneyFooter(children: [
                ParcPrimaryButton(
                  label: 'Je suis arrivé à destination',
                  onPressed: () => context.push(Routes.arrival(m.id)),
                ),
                DangerSoftButton(
                  label: 'Signaler un incident',
                  onPressed: () => ref.read(featuresProvider).driverIncident
                      ? _openIncidentSheet(context, m)
                      : openMaintenance(context, 'Signaler un incident'),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: ParcColors.headerChip, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: ParcColors.liveDot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('Mission en cours', style: parcText(12, weight: 800, color: ParcColors.surface)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${m.number} · ${stepLabel(7)}',
                  textAlign: TextAlign.right,
                  style: parcText(12, weight: 600, color: ParcColors.onDarkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Destination', style: parcText(13, color: ParcColors.onDarkMuted)),
          Semantics(
            header: true,
            child: Text(m.destination, style: parcText(30, weight: 800, color: ParcColors.surface, letterSpacing: -0.5)),
          ),
          if (m.purpose != null) Text(m.purpose!, style: parcText(13, color: ParcColors.onDarkMuted)),
        ],
      ),
    );
  }
}

/// Trip progress. No position nor origin in the database: progress is the share of time elapsed
/// between the departure check and the planned return (see README).
class _Progress extends StatelessWidget {
  const _Progress({required this.mission, required this.leftAt, required this.now});

  final Mission mission;
  final DateTime leftAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final total = m.plannedReturn.difference(leftAt).inSeconds;
    final done = now.difference(leftAt).inSeconds;
    final fraction = total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
    return Semantics(
      label: 'Progression du trajet',
      child: WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Départ', style: parcText(14, weight: 800)),
                Flexible(child: Text(m.destination, style: parcText(14, weight: 800), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: LayoutBuilder(
                builder: (context, c) {
                  final x = c.maxWidth * fraction;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 5,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 5,
                        width: x,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(color: ParcColors.primary, borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      Positioned(
                        left: (x - 10).clamp(0.0, c.maxWidth - 20),
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ParcColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: ParcColors.surface, width: 3),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('Départ ${FrenchDates.time(leftAt)}', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Retour prévu ${FrenchDates.shortDayTime(m.plannedReturn)}',
                    textAlign: TextAlign.right,
                    style: parcText(12, weight: 600, color: ParcColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openIncidentSheet(BuildContext context, Mission mission) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: ParcColors.scrim,
    builder: (_) => _IncidentSheet(mission: mission),
  );
}

class _IncidentSheet extends ConsumerStatefulWidget {
  const _IncidentSheet({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_IncidentSheet> createState() => _IncidentSheetState();
}

class _IncidentSheetState extends ConsumerState<_IncidentSheet> {
  int? _kind;
  bool _showError = false;
  bool _busy = false;
  bool _sent = false;
  String? _failure;
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final kind = _kind;
    if (kind == null) {
      setState(() => _showError = true);
      return;
    }
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(missionsGatewayProvider).reportIncident(
            missionId: widget.mission.id,
            kind: MissionFlowConfig.incidentKinds[kind],
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            blocksDeparture: false,
          );
      if (mounted) setState(() => _sent = true);
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() => _failure = e.message);
    } catch (_) {
      if (mounted) setState(() => _failure = 'Le signalement n’a pas pu être envoyé. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    final ready = _kind != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Semantics(
        container: true,
        label: 'Signaler un incident',
        child: Container(
          decoration: const BoxDecoration(
            color: ParcColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.paddingOf(context).bottom),
          child: SingleChildScrollView(
            child: _sent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: ParcColors.successBg, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const ParcIcon(ParcIcons.checkBold, size: 32, color: ParcColors.success),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Incident envoyé', textAlign: TextAlign.center, style: parcText(20, weight: 800)),
                      const SizedBox(height: 12),
                      Text(
                        'Le gestionnaire est averti. Vous pouvez poursuivre la mission.',
                        textAlign: TextAlign.center,
                        style: parcText(14, color: ParcColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ParcPrimaryButton(label: 'Reprendre la mission', height: 52, onPressed: close),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text('Signaler un incident', style: parcText(18, weight: 800)),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Fermer',
                            excludeSemantics: true,
                            child: Material(
                              color: ParcColors.dividerSoft,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: close,
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(child: ParcIcon(ParcIcons.cross, size: 18, color: ParcColors.text)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (i, label) in MissionFlowConfig.incidentKinds.indexed)
                            PillChoice(
                              label: label,
                              selected: _kind == i,
                              onTap: () => setState(() {
                                _kind = i;
                                _showError = false;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ParcTextField(
                        controller: _description,
                        height: null,
                        maxLines: 3,
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        hintText: "Décrivez ce qui s'est passé…",
                        semanticLabel: "Description de l'incident",
                      ),
                      if (_showError && !ready) ...[const SizedBox(height: 14), const FieldError("Choisissez la nature de l'incident.")],
                      if (_failure != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _failure!)],
                      const SizedBox(height: 14),
                      JourneyActionButton(label: "Envoyer l'incident", danger: true, ready: ready, busy: _busy, onPressed: _send),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
