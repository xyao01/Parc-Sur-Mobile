import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_gateway.dart';
import '../data/requests_providers.dart';
import '../domain/request_config.dart';
import '../domain/vehicle_request.dart';
import 'request_widgets.dart';

/// Mob-D06 · Détail et annulation (`annuler_demande`); « Modifier » reopens Mob-D02.
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) =>
      RequestLoader(requestId: requestId, builder: (context, r, now) => _Detail(request: r, now: now));
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.request, required this.now});

  final VehicleRequest request;
  final DateTime now;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;
  String? _error;

  Future<void> _askCancel() async {
    final r = widget.request;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: ParcColors.scrim,
      builder: (sheet) => Semantics(
        container: true,
        label: 'Annuler la demande',
        child: Container(
          decoration: const BoxDecoration(
            color: ParcColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 22, 20, 24 + MediaQuery.paddingOf(sheet).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Annuler cette demande ?', style: parcText(20, weight: 800))),
              const SizedBox(height: 14),
              Text(
                'La demande ${r.number} vers ${r.destination} sera retirée et le gestionnaire en sera informé. '
                'Cette action est définitive.',
                style: parcText(14, color: ParcColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              JourneyActionButton(label: 'Oui, annuler la demande', danger: true, onPressed: () => Navigator.of(sheet).pop(true)),
              const SizedBox(height: 14),
              ParcOutlinedButton(label: 'Non, la conserver', height: 48, onPressed: () => Navigator.of(sheet).pop(false)),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(requestsGatewayProvider).cancel(r.id, RequestConfig.cancelReason);
      ref.invalidate(myRequestsProvider);
    } on RequestsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'La demande n’a pas pu être annulée. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final now = widget.now;
    final cancelled = r.status == 'annulee';
    final decided = r.status == 'validee' || r.status == 'refusee';

    final List<Widget> footer;
    if (r.canEdit(now)) {
      footer = [
        Row(
          children: [
            Expanded(child: DangerSoftButton(label: 'Annuler', icon: false, height: 54, onPressed: _busy ? () {} : _askCancel)),
            const SizedBox(width: 10),
            Expanded(
              child: ParcPrimaryButton(label: 'Modifier', fontSize: 15, onPressed: () => context.push(Routes.editRequest(r.id))),
            ),
          ],
        ),
      ];
    } else if (r.canCancel(now)) {
      footer = [DangerSoftButton(label: 'Annuler', icon: false, height: 54, onPressed: _busy ? () {} : _askCancel)];
    } else {
      footer = [ParcPrimaryButton(label: "Retour à l'accueil", onPressed: () => context.go(Routes.requesterHome))];
    }

    return JourneyScaffold(
      header: JourneyHeader(
        title: 'Demande ${r.number}',
        subtitle: stepLabel(6),
        backLabel: 'Retour à mes demandes',
        onBack: () => requestBack(context, Routes.myRequests),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.status == 'attente')
            _Banner(
              icon: ParcIcons.clock,
              text: 'En attente de validation par le gestionnaire',
              bg: ParcColors.pendingBg,
              fg: ParcColors.pendingText,
            ),
          if (cancelled)
            const _Banner(icon: ParcIcons.cross, text: 'Demande annulée', bg: ParcColors.dangerSoft, fg: ParcColors.dangerStrong),
          const SizedBox(height: 14),
          RequestSummaryCard(
            destination: r.destination,
            purpose: r.purpose,
            departure: r.departure,
            plannedReturn: r.plannedReturn,
            passengers: r.passengers,
            withDriver: r.withDriver,
          ),
          const SizedBox(height: 14),
          RequestTimeline(request: r, now: now),
          if (decided) ...[
            const SizedBox(height: 4),
            Center(child: TextLink('Voir la décision du gestionnaire', onTap: () => context.push(Routes.requestDecision(r.id)))),
          ],
          if (_error != null) ...[const SizedBox(height: 14), ParcErrorAlert(message: _error!)],
        ],
      ),
      footer: footer,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.bg, required this.fg});

  final String icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            ParcIcon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: parcText(13, weight: 700, color: fg))),
          ],
        ),
      ),
    );
  }
}
