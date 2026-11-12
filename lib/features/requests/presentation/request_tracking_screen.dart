import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/features.dart';
import '../../../core/french_dates.dart';
import '../../../core/widgets/maintenance_screen.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parc_text_field.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_gateway.dart';
import '../data/requests_providers.dart';
import '../domain/request_config.dart';
import '../domain/vehicle_request.dart';
import 'request_widgets.dart';

/// Mob-D08 · Suivi de la mission (requester side).
/// The driver's actual departure time is not readable by the requester: planned times are shown (see README).
class RequestTrackingScreen extends StatelessWidget {
  const RequestTrackingScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return RequestLoader(
      requestId: requestId,
      builder: (context, r, now) {
        final state = r.stateAt(now);
        return Scaffold(
          backgroundColor: ParcColors.background,
          body: Column(
            children: [
              _Header(request: r, state: state),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Progress(request: r, now: now),
                      const SizedBox(height: 14),
                      StatGrid(tiles: [
                        StatTile(label: 'Heure de départ', value: FrenchDates.time(r.departure)),
                        StatTile(
                          label: 'Retour prévu',
                          value: '${FrenchDates.shortDay(r.plannedReturn)} ${FrenchDates.time(r.plannedReturn)}',
                          valueSize: 16,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      if (r.driver != null || r.vehicle != null)
                        WhiteCard(
                          radius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              InitialsAvatar(r.driver ?? r.vehicle!),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.driver ?? 'Sans chauffeur', style: parcText(14, weight: 800)),
                                    Text(
                                      [if (r.driver != null) 'Chauffeur', ?r.vehicle].join(' · '),
                                      style: parcText(12, color: ParcColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (r.driver != null) const CallButton(label: 'Appeler le chauffeur'),
                            ],
                          ),
                        ),
                      if (state == RequestState.terminee) ...[
                        const SizedBox(height: 4),
                        Center(child: TextLink('Voir la fin de mission', onTap: () => context.push(Routes.requestEnd(r.id)))),
                      ],
                    ],
                  ),
                ),
              ),
              JourneyFooter(children: [
                DangerSoftButton(
                  label: 'Signaler un problème',
                  height: 52,
                  onPressed: () => ProviderScope.containerOf(context).read(featuresProvider).requesterProblem
                      ? _openReport(context, r)
                      : openMaintenance(context, 'Signaler un problème'),
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
  const _Header({required this.request, required this.state});

  final VehicleRequest request;
  final RequestState state;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final top = MediaQuery.paddingOf(context).top;
    // « Mission en cours » once the departure time is past; before it, the planned departure (not in the prototype).
    final (String chip, Color dot) = switch (state) {
      RequestState.enCours => ('Mission en cours', ParcColors.liveDot),
      RequestState.terminee => ('Mission terminée', ParcColors.onDarkMuted),
      _ => ('Départ ${FrenchDates.shortDay(r.departure, capitalize: false)} ${FrenchDates.time(r.departure)}', ParcColors.accent),
    };
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 20 + top, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ParcHeaderBackButton(
                semanticLabel: 'Retour',
                onPressed: () => requestBack(context, Routes.myRequests),
                icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: ParcColors.headerChip, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(chip, style: parcText(12, weight: 800, color: ParcColors.surface))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(stepLabel(8), style: parcText(12, weight: 600, color: ParcColors.onDarkMuted)),
            ],
          ),
          const SizedBox(height: 14),
          Text('${r.number} · Destination', style: parcText(13, color: ParcColors.onDarkMuted)),
          Semantics(
            header: true,
            child: Text(r.destination, style: parcText(30, weight: 800, color: ParcColors.surface, letterSpacing: -0.5)),
          ),
          if (r.purpose.isNotEmpty) Text(r.purpose, style: parcText(13, color: ParcColors.onDarkMuted)),
        ],
      ),
    );
  }
}

/// No position nor origin in the database: progress is the share of time elapsed between departure and return.
class _Progress extends StatelessWidget {
  const _Progress({required this.request, required this.now});

  final VehicleRequest request;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final total = r.plannedReturn.difference(r.departure).inSeconds;
    final fraction = total <= 0 ? 1.0 : (now.difference(r.departure).inSeconds / total).clamp(0.0, 1.0);
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
                Flexible(child: Text(r.destination, style: parcText(14, weight: 800), overflow: TextOverflow.ellipsis)),
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
                  child: Text('Départ ${FrenchDates.time(r.departure)}', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Retour prévu ${FrenchDates.shortDayTime(r.plannedReturn)}',
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

Future<void> _openReport(BuildContext context, VehicleRequest request) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: ParcColors.scrim,
      builder: (_) => _ReportSheet(request: request),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.request});

  final VehicleRequest request;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
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
      await ref.read(requestsGatewayProvider).reportProblem(
            requestId: widget.request.id,
            kind: RequestConfig.problemKinds[kind],
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          );
      if (mounted) setState(() => _sent = true);
    } on RequestsGatewayException catch (e) {
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
        label: 'Signaler un problème',
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
                      Text('Signalement envoyé', textAlign: TextAlign.center, style: parcText(20, weight: 800)),
                      const SizedBox(height: 12),
                      Text(
                        'Le gestionnaire du parc a été informé.',
                        textAlign: TextAlign.center,
                        style: parcText(14, color: ParcColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ParcPrimaryButton(label: 'Fermer', height: 52, onPressed: close),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(header: true, child: Text('Signaler un problème', style: parcText(18, weight: 800))),
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
                          for (final (i, label) in RequestConfig.problemKinds.indexed)
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
                        hintText: 'Décrivez le problème…',
                        semanticLabel: 'Description du problème',
                      ),
                      if (_showError && !ready) ...[const SizedBox(height: 14), const FieldError('Choisissez le type de problème.')],
                      if (_failure != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _failure!)],
                      const SizedBox(height: 14),
                      JourneyActionButton(label: 'Envoyer au gestionnaire', danger: true, ready: ready, busy: _busy, onPressed: _send),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
