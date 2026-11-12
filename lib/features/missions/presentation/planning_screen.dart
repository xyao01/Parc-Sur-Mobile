import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../data/missions_providers.dart';
import '../domain/mission.dart';
import 'chauffeur_nav.dart';
import 'journey_widgets.dart';

/// Mob-C11 · Planning chauffeur (validated proposal): missions of `mes_missions_chauffeur()`
/// by week, grouped by departure day.
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday - 1));

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  late final DateTime _today = _dateOnly(ref.read(clockProvider)());
  late DateTime _monday = _mondayOf(_today);
  late int _day = _today.weekday - 1;

  DateTime get _selected => _monday.add(Duration(days: _day));

  void _changeWeek(int delta) {
    setState(() {
      _monday = _monday.add(Duration(days: 7 * delta));
      _day = _monday == _mondayOf(_today) ? _today.weekday - 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(missionsProvider);
    final missions = async.value ?? const <Mission>[];
    List<Mission> on(DateTime day) => missions.where((m) => FrenchDates.sameDay(m.departure, day)).toList();

    final days = [for (var i = 0; i < 7; i++) _monday.add(Duration(days: i))];
    final selected = on(_selected);
    final rest = [
      for (final (i, d) in days.indexed)
        if (i != _day) for (final m in on(d)) (i, m),
    ];
    final isToday = FrenchDates.sameDay(_selected, _today);

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
        SectionCaps('${FrenchDates.longDay(_selected)}${isToday ? " · aujourd'hui" : ''}'),
        const SizedBox(height: 14),
        if (selected.isEmpty)
          const _EmptyDay()
        else
          for (final (i, m) in selected.indexed) ...[if (i > 0) const SizedBox(height: 14), _MissionCard(mission: m)],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionCaps('Reste de la semaine'),
          const SizedBox(height: 14),
          for (final (i, (dayIndex, m)) in rest.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _RestTile(mission: m, onTap: () => setState(() => _day = dayIndex)),
          ],
        ],
      ];
    }

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          _Header(
            monday: _monday,
            days: days,
            selectedIndex: _day,
            today: _today,
            hasMission: (d) => on(d).isNotEmpty,
            onSelect: (i) => setState(() => _day = i),
            onWeek: _changeWeek,
          ),
          Expanded(
            child: RefreshIndicator(
              color: ParcColors.primary,
              onRefresh: () => ref.refresh(missionsProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ChauffeurBottomNav(currentIndex: 1),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.monday,
    required this.days,
    required this.selectedIndex,
    required this.today,
    required this.hasMission,
    required this.onSelect,
    required this.onWeek,
  });

  final DateTime monday;
  final List<DateTime> days;
  final int selectedIndex;
  final DateTime today;
  final bool Function(DateTime) hasMission;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onWeek;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ParcColors.navy,
      padding: EdgeInsets.fromLTRB(20, 22 + top, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(header: true, child: Text('Planning', style: parcText(22, weight: 800, color: ParcColors.surface))),
              ),
              Text(FrenchDates.monthYear(monday), style: parcText(13, weight: 600, color: ParcColors.onDarkMuted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ParcHeaderBackButton(
                semanticLabel: 'Semaine précédente',
                onPressed: () => onWeek(-1),
                icon: const ParcIcon(ParcIcons.back, size: 20, color: ParcColors.surface),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  FrenchDates.weekRange(monday),
                  textAlign: TextAlign.center,
                  style: parcText(14, weight: 700, color: ParcColors.surface),
                ),
              ),
              const SizedBox(width: 8),
              ParcHeaderBackButton(
                semanticLabel: 'Semaine suivante',
                onPressed: () => onWeek(1),
                icon: const ParcIcon(ParcIcons.chevronRight, size: 20, color: ParcColors.surface),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, d) in days.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _DayButton(
                    day: d,
                    selected: i == selectedIndex,
                    today: FrenchDates.sameDay(d, today),
                    hasMission: hasMission(d),
                    onTap: () => onSelect(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.today,
    required this.hasMission,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool hasMission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = [
      FrenchDates.longDay(day),
      if (hasMission) 'mission prévue',
      if (today) "aujourd'hui",
    ].join(', ');
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? ParcColors.surface : (today ? ParcColors.headerChip : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FrenchDates.weekdayShort(day).toUpperCase(),
                  style: parcText(11, weight: 700, color: selected ? ParcColors.textMuted : ParcColors.onDarkMuted),
                ),
                Text('${day.day}', style: parcText(18, weight: 800, color: selected ? ParcColors.navy : ParcColors.surface)),
                const SizedBox(height: 2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasMission ? ParcColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _period(Mission m) =>
    '${FrenchDates.shortDay(m.departure)} ${FrenchDates.time(m.departure)} → '
    '${FrenchDates.shortDay(m.plannedReturn, capitalize: false)} ${FrenchDates.time(m.plannedReturn)}';

String _detail(Mission m) => '${m.vehicle.label} · ${m.passengers} passager${m.passengers > 1 ? 's' : ''}';

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final (String status, Color chipBg, Color chipFg, Color border, String? route) = m.returnCheckDone
        ? ('Retour enregistré', ParcColors.primarySoft, ParcColors.primary, ParcColors.divider, null)
        : m.inProgress
            ? ('En cours', ParcColors.successBg, ParcColors.success, ParcColors.success, Routes.inProgress(m.id))
            : ('À préparer', ParcColors.pendingBg, ParcColors.pendingText, ParcColors.primary, Routes.departurePreparation(m.id));
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 1.5),
      ),
      child: InkWell(
        onTap: route == null ? null : () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusChip(status, bg: chipBg, fg: chipFg),
                  Text(m.number, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Text(m.destination, style: parcText(17, weight: 800)),
              const SizedBox(height: 10),
              Text(_period(m), style: parcText(13, color: ParcColors.textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(_detail(m), style: parcText(13, weight: 600, color: ParcColors.textSecondary))),
                  const SizedBox(width: 12),
                  const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestTile extends StatelessWidget {
  const _RestTile({required this.mission, required this.onTap});

  final Mission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Material(
      color: ParcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ParcColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Text(_detail(m), style: parcText(13, color: ParcColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const ParcIcon(ParcIcons.chevronRight, size: 18, color: ParcColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const DashedBorderPainter(color: ParcColors.inputBorder, strokeWidth: 1, radius: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        decoration: BoxDecoration(color: ParcColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Text('Aucune mission ce jour.', textAlign: TextAlign.center, style: parcText(14, color: ParcColors.textMuted)),
      ),
    );
  }
}
