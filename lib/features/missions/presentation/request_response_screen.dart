import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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

/// Mob-C04 · Acceptation ou refus. The answer goes through
/// `MissionsGateway.respondToRequest` (no backend yet: see README).
class RequestResponseScreen extends StatelessWidget {
  const RequestResponseScreen({super.key, required this.missionId, required this.accept});

  final String missionId;
  final bool accept;

  @override
  Widget build(BuildContext context) {
    return MissionLoader(
      missionId: missionId,
      builder: (context, m) => _Response(mission: m, initialAccept: accept),
    );
  }
}

enum _Send { idle, sending, sent, failed }

class _Response extends ConsumerStatefulWidget {
  const _Response({required this.mission, required this.initialAccept});

  final Mission mission;
  final bool initialAccept;

  @override
  ConsumerState<_Response> createState() => _ResponseState();
}

class _ResponseState extends ConsumerState<_Response> {
  late bool _accept = widget.initialAccept;
  _Send _acceptState = _Send.idle;
  _Send _refuseState = _Send.idle;
  String? _error;
  int? _reason;
  bool _showReasonError = false;
  final _details = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_accept) WidgetsBinding.instance.addPostFrameCallback((_) => _sendAccept());
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _sendAccept() async {
    if (_acceptState == _Send.sending || _acceptState == _Send.sent) return;
    setState(() {
      _acceptState = _Send.sending;
      _error = null;
    });
    try {
      await ref.read(missionsGatewayProvider).respondToRequest(missionId: widget.mission.id, accept: true);
      if (mounted) setState(() => _acceptState = _Send.sent);
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() { _acceptState = _Send.failed; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _acceptState = _Send.failed; _error = 'Votre réponse n’a pas pu être envoyée. Réessayez.'; });
    }
  }

  Future<void> _sendRefusal() async {
    final reason = _reason;
    if (reason == null) {
      setState(() => _showReasonError = true);
      return;
    }
    if (_refuseState == _Send.sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _refuseState = _Send.sending;
      _error = null;
    });
    try {
      await ref.read(missionsGatewayProvider).respondToRequest(
            missionId: widget.mission.id,
            accept: false,
            reason: MissionFlowConfig.refusalReasons[reason],
            details: _details.text.trim().isEmpty ? null : _details.text.trim(),
          );
      if (mounted) setState(() => _refuseState = _Send.sent);
    } on MissionsGatewayException catch (e) {
      if (mounted) setState(() { _refuseState = _Send.failed; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _refuseState = _Send.failed; _error = 'Votre réponse n’a pas pu être envoyée. Réessayez.'; });
    }
  }

  void _leave(String route) {
    ref.invalidate(pendingRequestsProvider);
    ref.invalidate(missionsProvider);
    context.go(route);
  }

  void _select(int i) {
    if (_acceptState == _Send.sent || _refuseState == _Send.sent) return;
    setState(() {
      _accept = i == 0;
      _error = null;
    });
    if (_accept) _sendAccept();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final (body, footer) = _accept ? _acceptView(m) : _refuseView(m);
    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Votre réponse',
        subtitle: '${m.number} · ${stepLabel(4)}',
        backLabel: 'Retour aux détails',
        onBack: () => journeyBack(context),
        bottomPadding: 16,
        bottom: SegmentedChoice(
          onDark: true,
          labels: const ['Accepter', 'Refuser'],
          selected: _accept ? 0 : 1,
          selectedColors: const [ParcColors.primary, ParcColors.danger],
          onChanged: _select,
        ),
      ),
      bodyPadding: EdgeInsets.fromLTRB(20, _isResult ? 32 : 18, 20, 16),
      body: body,
      footer: footer,
    );
  }

  bool get _isResult => _accept ? _acceptState == _Send.sent : _refuseState == _Send.sent;

  (Widget, List<Widget>) _acceptView(Mission m) {
    if (_acceptState != _Send.sent) {
      return (
        _acceptState == _Send.failed
            ? ParcErrorAlert(message: _error!)
            : const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: ParcColors.primary)),
              ),
        [ParcOutlinedButton(label: "Retour à l'accueil", height: 48, onPressed: () => _leave(Routes.missions))],
      );
    }
    return (
      ResultView(
        icon: ParcIcons.checkBold,
        iconBg: ParcColors.successBg,
        iconColor: ParcColors.success,
        title: 'Mission acceptée',
        message: Text(
          '${m.requester} et le gestionnaire du parc sont notifiés. La mission est ajoutée à votre planning.',
          textAlign: TextAlign.center,
          style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
        ),
        child: WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.destination, style: parcText(16, weight: 800)),
              const SizedBox(height: 6),
              Text(_period(m), style: parcText(13, color: ParcColors.textMuted)),
              const SizedBox(height: 6),
              Text('${m.vehicle.label} · ${m.passengers} passager${m.passengers > 1 ? 's' : ''}',
                  style: parcText(13, color: ParcColors.textMuted)),
            ],
          ),
        ),
      ),
      [
        ParcPrimaryButton(label: 'Préparer le départ', onPressed: () => _leave(Routes.departurePreparation(m.id))),
        ParcOutlinedButton(label: "Retour à l'accueil", height: 48, onPressed: () => _leave(Routes.missions)),
      ],
    );
  }

  (Widget, List<Widget>) _refuseView(Mission m) {
    if (_refuseState == _Send.sent) {
      final reason = MissionFlowConfig.refusalReasons[_reason!];
      return (
        ResultView(
          icon: ParcIcons.cross,
          iconBg: ParcColors.dangerSoft,
          iconColor: ParcColors.danger,
          iconSize: 40,
          title: 'Refus envoyé',
          message: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Motif transmis au gestionnaire : '),
              TextSpan(text: reason, style: parcText(15, weight: 800, color: ParcColors.textSecondary, height: 1.5)),
              TextSpan(text: '. La demande ${m.number} sera réaffectée.'),
            ]),
            textAlign: TextAlign.center,
            style: parcText(15, color: ParcColors.textSecondary, height: 1.5),
          ),
        ),
        [ParcPrimaryButton(label: "Retour à l'accueil", onPressed: () => _leave(Routes.missions))],
      );
    }
    final ready = _reason != null;
    return (
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldCaption('Motif du refus', suffix: '(obligatoire)', suffixColor: ParcColors.danger),
          const SizedBox(height: 8),
          for (final (i, label) in MissionFlowConfig.refusalReasons.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _ReasonOption(
              label: label,
              selected: _reason == i,
              onTap: () => setState(() { _reason = i; _showReasonError = false; }),
            ),
          ],
          if (_showReasonError && !ready) ...[
            const SizedBox(height: 4),
            const FieldError('Sélectionnez un motif pour envoyer votre refus.'),
          ],
          const SizedBox(height: 14),
          const FieldCaption('Précisions', suffix: '(facultatif)'),
          const SizedBox(height: 6),
          ParcTextField(
            controller: _details,
            height: null,
            maxLines: 3,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            hintText: 'Ex. : déjà en mission le 6 novembre…',
          ),
          const SizedBox(height: 14),
          const InfoNote('Le gestionnaire recevra votre motif et pourra affecter un autre chauffeur.'),
          if (_refuseState == _Send.failed) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      [
        JourneyActionButton(
          label: 'Confirmer le refus',
          danger: true,
          ready: ready,
          busy: _refuseState == _Send.sending,
          onPressed: _sendRefusal,
        ),
      ],
    );
  }
}

String _period(Mission m) =>
    '${FrenchDates.shortDay(m.departure)} ${FrenchDates.time(m.departure)} → '
    '${FrenchDates.shortDay(m.plannedReturn, capitalize: false)} ${FrenchDates.time(m.plannedReturn)}';

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: selected ? ParcColors.primarySoft : ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? ParcColors.primary : ParcColors.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: ParcColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? ParcColors.primary : ParcColors.checkboxBorder, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: selected ? ParcColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
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
