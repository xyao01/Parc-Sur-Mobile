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
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_providers.dart';
import '../domain/vehicle_request.dart';

/// Resolves a request by id for the requester screens (Mob-D04…D10).
class RequestLoader extends ConsumerWidget {
  const RequestLoader({super.key, required this.requestId, required this.builder});

  final String requestId;
  final Widget Function(BuildContext context, VehicleRequest request, DateTime now) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestByIdProvider(requestId));
    final r = async.value;
    if (r != null) return builder(context, r, ref.watch(clockProvider)());
    return Scaffold(
      backgroundColor: ParcColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: async.isLoading
              ? const Center(child: CircularProgressIndicator(color: ParcColors.primary))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ParcErrorAlert(
                      message: async.hasError ? 'Impossible de charger la demande.' : 'Cette demande est introuvable.',
                    ),
                    const SizedBox(height: 12),
                    ParcOutlinedButton(
                      label: "Retour à l'accueil",
                      height: 46,
                      onPressed: () => context.go(Routes.requesterHome),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

void requestBack(BuildContext context, [String fallback = Routes.requesterHome]) =>
    context.canPop() ? context.pop() : context.go(fallback);

/// Screen opened by a request card, by state (Mob-D05 links).
String routeForRequest(VehicleRequest r, DateTime now) => switch (r.stateAt(now)) {
      RequestState.attente || RequestState.annulee => Routes.requestDetail(r.id),
      RequestState.validee || RequestState.refusee => Routes.requestDecision(r.id),
      RequestState.enCours => Routes.requestTracking(r.id),
      RequestState.terminee => Routes.requestEnd(r.id),
    };

String passengersLabel(int n) => '$n passager${n > 1 ? 's' : ''}';

/// « Suivi de la demande » (Mob-D04, D06): sent → manager review → vehicle and driver.
class RequestTimeline extends StatelessWidget {
  const RequestTimeline({super.key, required this.request, required this.now, this.reviewInProgressLabel = false});

  final VehicleRequest request;
  final DateTime now;

  /// Mob-D04 shows « En cours » under the review step.
  final bool reviewInProgressLabel;

  @override
  Widget build(BuildContext context) {
    final decided = request.status != 'attente' && request.status != 'annulee';
    return Semantics(
      label: 'Suivi de la demande',
      container: true,
      child: WhiteCard(
        child: Column(
          children: [
            _Step(
              done: true,
              number: 1,
              title: 'Demande envoyée',
              subtitle: FrenchDates.atLabel(request.createdAt, now),
            ),
            const SizedBox(height: 14),
            _Step(
              done: decided,
              current: request.status == 'attente',
              number: 2,
              title: 'Examen par le gestionnaire',
              subtitle: request.status == 'attente' && reviewInProgressLabel ? 'En cours' : null,
            ),
            const SizedBox(height: 14),
            _Step(done: request.status == 'validee', number: 3, title: 'Affectation du véhicule et du chauffeur'),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.number, required this.title, this.subtitle, this.current = false});

  final bool done;
  final bool current;
  final int number;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = done
        ? (ParcColors.success, ParcColors.surface)
        : current
            ? (ParcColors.pendingBg, ParcColors.pendingText)
            : (ParcColors.dividerSoft, ParcColors.textMuted);
    final active = done || current;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: done
              ? ParcIcon(ParcIcons.check, size: 14, color: fg)
              : Text('$number', style: parcText(13, weight: 800, color: fg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: parcText(14, weight: active ? 800 : 700, color: active ? ParcColors.text : ParcColors.textMuted)),
              if (subtitle != null) Text(subtitle!, style: parcText(12, color: ParcColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// White card with the destination, purpose and the 2×2 details (Mob-D03, D06).
class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({
    super.key,
    required this.destination,
    required this.purpose,
    required this.departure,
    required this.plannedReturn,
    required this.passengers,
    required this.withDriver,
    this.notes,
    this.footer,
  });

  final String destination;
  final String purpose;
  final DateTime departure;
  final DateTime plannedReturn;
  final int passengers;
  final bool withDriver;
  final String? notes;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // No origin in the database: destination only (see README).
          Text(destination, style: parcText(20, weight: 800)),
          const SizedBox(height: 12),
          Text(purpose, style: parcText(14, color: ParcColors.textSecondary)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ParcColors.dividerSoft),
          const SizedBox(height: 12),
          DetailsGrid(valueWeight: 800, entries: [
            ('Départ', FrenchDates.shortDayTime(departure), color: null),
            ('Retour', FrenchDates.shortDayTime(plannedReturn), color: null),
            ('Passagers', '$passengers', color: null),
            ('Chauffeur', withDriver ? 'Demandé' : 'Non demandé', color: null),
          ]),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: ParcColors.background, borderRadius: BorderRadius.circular(10)),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Précisions : ', style: parcText(13, weight: 800, color: ParcColors.textSecondary, height: 1.5)),
                TextSpan(text: notes!.trim(), style: parcText(13, color: ParcColors.textSecondary, height: 1.5)),
              ])),
            ),
          ],
          ?footer,
        ],
      ),
    );
  }
}

/// Text link in the primary colour (« Voir toutes mes demandes », « Modifier la demande »).
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: parcText(14, weight: 800, color: ParcColors.primary)),
        ),
      ),
    );
  }
}
