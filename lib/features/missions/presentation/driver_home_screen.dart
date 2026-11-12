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
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import 'chauffeur_nav.dart';
import 'journey_widgets.dart';

/// Mob-C01 · Accueil chauffeur.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  /// « Mission du jour »: leaves today, or already under way (left, not yet back).
  static bool isToday(Mission m, DateTime now) =>
      FrenchDates.sameDay(m.departure, now) || (m.inProgress) || (!m.departure.isAfter(now) && m.plannedReturn.isAfter(now));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final driver = ref.watch(sessionProvider);
    final async = ref.watch(missionsProvider);
    final pending = ref.watch(pendingRequestsProvider).value ?? const <Mission>[];
    final missions = async.value ?? const <Mission>[];
    final todays = missions.where((m) => isToday(m, now)).toList();
    final upcoming = missions.where((m) => m.departure.isAfter(now) && !isToday(m, now)).toList();

    final List<Widget> content;
    if (async.isLoading && !async.hasValue) {
      content = const [SizedBox(height: 40), Center(child: CircularProgressIndicator(color: ParcColors.primary))];
    } else if (async.hasError && !async.hasValue) {
      content = [
        const ParcErrorAlert(message: 'Impossible de charger vos missions.'),
        const SizedBox(height: 12),
        ParcOutlinedButton(label: 'Réessayer', height: 46, onPressed: () => ref.invalidate(missionsProvider)),
      ];
    } else {
      content = [
        Row(
          children: [
            Expanded(child: _Stat(valueKey: const Key('home.stat.today'), value: todays.length, label: "Mission aujourd'hui", color: ParcColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(valueKey: const Key('home.stat.new'), value: pending.length, label: 'Nouvelle demande', color: ParcColors.pendingText)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(valueKey: const Key('home.stat.upcoming'), value: upcoming.length, label: 'À venir', color: ParcColors.text)),
          ],
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionCaps('Nouvelle demande'),
          const SizedBox(height: 14),
          for (final r in pending) ...[_PendingCard(request: r), const SizedBox(height: 14)],
        ] else
          const SizedBox(height: 14),
        const SizedBox(height: 6),
        const SectionCaps('Mission du jour'),
        const SizedBox(height: 14),
        if (todays.isEmpty) Text("Aucune mission aujourd'hui.", style: parcText(14, color: ParcColors.textMuted)),
        for (final m in todays) ...[_TodayCard(mission: m), const SizedBox(height: 14)],
      ];
    }

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          if (driver != null) _Header(driver: driver, now: now, pending: pending),
          Expanded(
            child: RefreshIndicator(
              color: ParcColors.primary,
              onRefresh: () {
                ref.invalidate(pendingRequestsProvider);
                return ref.refresh(missionsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ChauffeurBottomNav(
        currentIndex: 0,
        onAlerts: pending.isEmpty ? null : () => context.push(Routes.requestNotice(pending.first.id)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.driver, required this.now, required this.pending});

  final MobileProfile driver;
  final DateTime now;
  final List<Mission> pending;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final count = pending.length;
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 20),
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
                label: count == 0 ? 'Notifications' : 'Notifications : $count nouvelle${count > 1 ? 's' : ''} demande${count > 1 ? 's' : ''}',
                excludeSemantics: true,
                child: Material(
                  color: ParcColors.headerChip,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: count == 0 ? null : () => context.push(Routes.requestNotice(pending.first.id)),
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        children: [
                          const Center(child: ParcIcon(ParcIcons.bell, size: 22, color: ParcColors.surface)),
                          if (count > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 16),
                                height: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(color: ParcColors.accent, borderRadius: BorderRadius.circular(999)),
                                alignment: Alignment.center,
                                child: Text('$count', style: parcText(10, weight: 800, color: ParcColors.navy)),
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
                child: Text(driver.initials, style: parcText(18, weight: 800, color: ParcColors.surface)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, ${driver.firstName}', style: parcText(22, weight: 800, color: ParcColors.surface)),
                    // The prototype adds the driver's fleet (« · Parc central »): not in profil_mobile().
                    Text('Chauffeur', style: parcText(13, color: ParcColors.onDarkMuted)),
                    Text(FrenchDates.longDay(now), style: parcText(13, color: ParcColors.onDarkMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AvailabilityRow(),
        ],
      ),
    );
  }
}

/// « Je suis disponible »: shown as in the prototype, not editable (no backend yet, see README).
class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(color: ParcColors.headerChip, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Je suis disponible', style: parcText(14, weight: 700, color: ParcColors.surface)),
                Text('Les nouvelles demandes peuvent vous être confiées',
                    style: parcText(12, color: ParcColors.onPrimaryMuted)),
              ],
            ),
          ),
          Semantics(
            toggled: true,
            enabled: false,
            label: 'Disponibilité',
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: ParcColors.accent, borderRadius: BorderRadius.circular(999)),
              alignment: Alignment.centerRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: ParcColors.surface, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
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

/// No origin in the database: the route shows the destination only (see README).
class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.request});

  final Mission request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final received = r.receivedAt;
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ParcColors.accent, width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.requestNotice(r.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const StatusChip('À répondre', bg: ParcColors.pendingBg, fg: ParcColors.pendingText),
                  if (received != null)
                    Text('Reçue à ${FrenchDates.time(received)}', style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.destination, style: parcText(17, weight: 800)),
              const SizedBox(height: 10),
              Text(
                '${FrenchDates.shortDay(r.departure)} ${FrenchDates.time(r.departure)} → '
                '${FrenchDates.shortDay(r.plannedReturn, capitalize: false)} ${FrenchDates.time(r.plannedReturn)} · '
                '${r.requester} · ${_passengers(r.passengers)}',
                style: parcText(13, color: ParcColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _passengers(int n) => '$n passager${n > 1 ? 's' : ''}';

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final String? action;
    final String? route;
    if (!m.departureCheckDone) {
      action = 'Commencer le contrôle de départ';
      route = Routes.departurePreparation(m.id);
    } else if (m.inProgress) {
      // Not in the prototype: a mission already started is resumed from here (C07).
      action = 'Reprendre la mission en cours';
      route = Routes.inProgress(m.id);
    } else {
      action = null;
      route = null;
    }
    return WhiteCard(
      border: ParcColors.primary,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip('Départ à ${FrenchDates.time(m.departure)}', bg: ParcColors.primarySoft, fg: ParcColors.primary),
              Text(m.number, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(m.destination, style: parcText(17, weight: 800)),
          const SizedBox(height: 10),
          Text('${m.vehicle.label} · ${m.requester} · ${_passengers(m.passengers)}',
              style: parcText(13, color: ParcColors.textMuted)),
          if (action != null) ...[
            const SizedBox(height: 10),
            ParcPrimaryButton(
              label: action,
              height: 48,
              radius: 12,
              fontSize: 15,
              onPressed: () => context.push(route!),
            ),
          ],
        ],
      ),
    );
  }
}
