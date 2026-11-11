import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../../core/widgets/parcsur_logo.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/mobile_profile.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import 'chauffeur_nav.dart';

/// Mobile · Mes missions (chauffeur).
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final driver = ref.watch(sessionProvider)!;
    final missions = ref.watch(missionsProvider);
    final todays = missions.where((m) => FrenchDates.sameDay(m.departure, now)).toList();
    final upcoming = missions.where((m) => m.departure.isAfter(now) && !FrenchDates.sameDay(m.departure, now)).toList();
    final count = todays.length;
    final subtitle = '${FrenchDates.longDay(now)} · $count mission${count > 1 ? 's' : ''} aujourd\'hui';

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          _Header(driver: driver, subtitle: subtitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Mission du jour', header: true),
                const SizedBox(height: 14),
                for (final m in todays) ...[_TodayMissionCard(mission: m), const SizedBox(height: 14)],
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const _SectionTitle('À venir'),
                  const SizedBox(height: 14),
                  for (final m in upcoming) ...[_UpcomingMissionTile(mission: m), const SizedBox(height: 14)],
                ],
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Expanded(child: _QuickAction(label: 'Saisir un plein', icon: ParcIcons.fuel, iconColor: ParcColors.primary)),
                    SizedBox(width: 10),
                    Expanded(child: _QuickAction(label: 'Signaler un incident', icon: ParcIcons.warning, iconColor: ParcColors.danger)),
                  ],
                ),
              ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ChauffeurBottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.driver, required this.subtitle});

  final MobileProfile driver;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ParcSurMark(size: 28),
              const SizedBox(width: 8),
              const ParcSurWordmark(fontSize: 18),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: ParcColors.headerChip, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(driver.initials, style: parcText(13, weight: 800, color: ParcColors.surface)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Bonjour, ${driver.firstName}', style: parcText(22, weight: 800, color: ParcColors.surface)),
          Text(subtitle, style: parcText(13, color: ParcColors.onDarkMuted)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: parcText(13, weight: 800, color: ParcColors.textMuted, letterSpacing: 0.5),
      ),
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  const _TodayMissionCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ParcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ParcColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: ParcColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                child: Text('Départ à ${FrenchDates.time(m.departure)}', style: parcText(12, weight: 800, color: ParcColors.primary)),
              ),
              Text(m.id, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: '${m.origin} vers ${m.destination}',
            excludeSemantics: false,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(m.origin, style: parcText(18, weight: 800)),
                const ParcIcon(ParcIcons.arrowRight, size: 18, color: ParcColors.accent),
                Text(m.destination, style: parcText(18, weight: 800)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailsGrid(entries: [
            ('Véhicule', m.vehicle?.label ?? 'À confirmer'),
            ('Retour prévu', FrenchDates.shortDayTime(m.plannedReturn)),
            ('Demandeur', m.requester),
            ('Passagers', '${m.passengers}'),
          ]),
          const SizedBox(height: 12),
          ParcPrimaryButton(
            label: 'Commencer le contrôle de départ',
            height: 52,
            onPressed: () => context.push('/missions/${m.id}/controle-depart'),
            trailing: const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.surface),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    Widget cell((String, String) e) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.$1, style: parcText(13, weight: 600, color: ParcColors.textMuted)),
            const SizedBox(height: 2),
            Text(e.$2, style: parcText(13, weight: 700)),
          ],
        );
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cell(entries[i])),
          const SizedBox(width: 10),
          Expanded(child: i + 1 < entries.length ? cell(entries[i + 1]) : const SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }
}

class _UpcomingMissionTile extends StatelessWidget {
  const _UpcomingMissionTile({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final vehicle = m.vehicle?.model ?? 'Véhicule à confirmer';
    final detail =
        '$vehicle · ${FrenchDates.time(m.departure)} → ${FrenchDates.weekdayShort(m.plannedReturn)} ${FrenchDates.time(m.plannedReturn)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ParcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ParcColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(FrenchDates.weekdayShort(m.departure).toUpperCase(),
                    style: parcText(11, weight: 700, color: ParcColors.textMuted)),
                Text('${m.departure.day}', style: parcText(22, weight: 800)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.destination, style: parcText(15, weight: 700)),
                Text(detail, style: parcText(13, color: ParcColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.textMuted),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.iconColor});

  final String label;
  final String icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ParcColors.divider),
      ),
      child: InkWell(
        // Target screens not designed yet (see README, « Points ouverts »).
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ParcIcon(icon, color: iconColor),
              const SizedBox(height: 6),
              Text(label, style: parcText(14, weight: 700), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
