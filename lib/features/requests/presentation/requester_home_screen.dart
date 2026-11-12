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
import '../../../core/widgets/parcsur_logo.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../data/requests_providers.dart';
import '../domain/vehicle_request.dart';
import 'demandeur_nav.dart';
import 'request_widgets.dart';

/// Mob-D01 · Accueil demandeur.
class RequesterHomeScreen extends ConsumerWidget {
  const RequesterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final profile = ref.watch(sessionProvider);
    final async = ref.watch(myRequestsProvider);
    final requests = async.value ?? const <VehicleRequest>[];
    int count(RequestState s) => requests.where((r) => r.stateAt(now) == s).length;
    final inProgress = requests.where((r) => r.stateAt(now) == RequestState.enCours).toList()
      ..sort((a, b) => a.departure.compareTo(b.departure));
    final latest = requests.isEmpty ? null : requests.first;

    final List<Widget> content;
    if (async.isLoading && !async.hasValue) {
      content = const [SizedBox(height: 40), Center(child: CircularProgressIndicator(color: ParcColors.primary))];
    } else if (async.hasError && !async.hasValue) {
      content = [
        const ParcErrorAlert(message: 'Impossible de charger vos demandes.'),
        const SizedBox(height: 12),
        ParcOutlinedButton(label: 'Réessayer', height: 46, onPressed: () => ref.invalidate(myRequestsProvider)),
      ];
    } else {
      content = [
        Row(
          children: [
            Expanded(child: _Stat(valueKey: const Key('requester.stat.pending'), value: count(RequestState.attente), label: 'En attente', color: ParcColors.pendingText)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(valueKey: const Key('requester.stat.inProgress'), value: count(RequestState.enCours), label: 'En cours', color: ParcColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(valueKey: const Key('requester.stat.validated'), value: count(RequestState.validee), label: 'Validée', color: ParcColors.success)),
          ],
        ),
        for (final m in inProgress) ...[
          const SizedBox(height: 18),
          const SectionCaps('Mission en cours'),
          const SizedBox(height: 14),
          _InProgressCard(request: m),
        ],
        const SizedBox(height: 20),
        const SectionCaps('Dernière demande'),
        const SizedBox(height: 14),
        if (latest == null)
          Text('Aucune demande pour le moment.', style: parcText(14, color: ParcColors.textMuted))
        else
          _LatestTile(request: latest, now: now),
        const SizedBox(height: 4),
        Center(child: TextLink('Voir toutes mes demandes', onTap: () => context.go(Routes.myRequests))),
      ];
    }

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          if (profile != null) _Header(profile: profile, unread: ref.watch(unreadAlertsCountProvider)),
          Expanded(
            child: RefreshIndicator(
              color: ParcColors.primary,
              onRefresh: () => ref.refresh(myRequestsProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NewRequestCard(onTap: () => context.push(Routes.newRequest)),
                    const SizedBox(height: 14),
                    ...content,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DemandeurBottomNav(currentIndex: 0),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.unread});

  final MobileProfile profile;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ParcSurMark(size: 28),
              const SizedBox(width: 8),
              const ParcSurWordmark(fontSize: 18),
              const Spacer(),
              Semantics(
                button: true,
                label: unread == 0 ? 'Notifications' : 'Notifications : $unread nouvelle${unread > 1 ? 's' : ''}',
                excludeSemantics: true,
                child: Material(
                  color: ParcColors.headerChip,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => context.go(Routes.alerts),
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        children: [
                          const Center(child: ParcIcon(ParcIcons.bell, size: 22, color: ParcColors.surface)),
                          if (unread > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 16),
                                height: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(color: ParcColors.accent, borderRadius: BorderRadius.circular(999)),
                                alignment: Alignment.center,
                                child: Text('$unread', style: parcText(10, weight: 800, color: ParcColors.navy)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: ParcColors.headerChip, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(profile.initials, style: parcText(18, weight: 800, color: ParcColors.surface)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, ${profile.firstName}', style: parcText(22, weight: 800, color: ParcColors.surface)),
                    // The prototype adds the requester's department (« · [Direction] »): not in profil_mobile().
                    Text('Demandeur', style: parcText(13, color: ParcColors.onDarkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: ParcColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: ParcColors.headerChip, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: const ParcIcon(ParcIcons.plus, size: 26, color: ParcColors.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nouvelle demande de véhicule', style: parcText(17, weight: 800, color: ParcColors.surface)),
                      Text('Mission, dates, passagers', style: parcText(13, color: ParcColors.onPrimaryMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const ParcIcon(ParcIcons.chevronRight, size: 20, color: ParcColors.surface),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.valueKey, required this.value, required this.label, required this.color});

  final Key valueKey;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParcColors.divider),
      ),
      child: Column(
        children: [
          Text('$value', key: valueKey, style: parcText(24, weight: 800, color: color)),
          Text(label, textAlign: TextAlign.center, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
        ],
      ),
    );
  }
}

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({required this.request});

  final VehicleRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final detail = [
      ?r.vehicleName,
      if (r.driver != null) 'chauffeur ${r.driver}',
      'retour ${FrenchDates.weekdayShort(r.plannedReturn)} ${FrenchDates.time(r.plannedReturn)}',
    ].join(' · ');
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ParcColors.primary, width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.requestTracking(r.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: ParcColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('En cours', style: parcText(12, weight: 800, color: ParcColors.primary)),
                      ],
                    ),
                  ),
                  Text(r.number, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              // No origin in the database: destination only (see README).
              Text(r.destination, style: parcText(17, weight: 800)),
              const SizedBox(height: 8),
              Text(detail, style: parcText(13, color: ParcColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestTile extends StatelessWidget {
  const _LatestTile({required this.request, required this.now});

  final VehicleRequest request;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final state = r.stateAt(now);
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ParcColors.divider),
      ),
      child: InkWell(
        onTap: () => context.push(routeForRequest(r, now)),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.destination, style: parcText(15, weight: 800)),
                    Text(
                      '${FrenchDates.dayRange(r.departure, r.plannedReturn)} · ${passengersLabel(r.passengers)}',
                      style: parcText(13, color: ParcColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(state.label, bg: state.bg, fg: state.fg),
            ],
          ),
        ),
      ),
    );
  }
}
