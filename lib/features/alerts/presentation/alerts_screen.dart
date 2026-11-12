import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_role.dart';
import '../../../core/clock.dart';
import '../../../core/french_dates.dart';
import '../../../core/theme/parcsur_colors.dart';
import '../../../core/theme/parcsur_text.dart';
import '../../../core/widgets/parc_buttons.dart';
import '../../../core/widgets/parc_error_alert.dart';
import '../../../core/widgets/parc_icon.dart';
import '../../auth/application/session.dart';
import '../../missions/presentation/chauffeur_nav.dart';
import '../../missions/presentation/journey_widgets.dart';
import '../../requests/presentation/demandeur_nav.dart';
import '../data/alerts_gateway.dart';
import '../data/alerts_providers.dart';
import '../domain/app_alert.dart';

/// Mob-C12 · Alertes (chauffeur et demandeur), validated proposal.
/// Driver alerts: `mes_notifications_chauffeur()`; requester alerts: table `notification`.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _unreadOnly = false;
  String? _error;

  Future<void> _markRead([List<AppAlert>? alerts]) async {
    setState(() => _error = null);
    try {
      await ref.read(alertsProvider.notifier).markRead(alerts);
    } on AlertsGatewayException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Les alertes n’ont pas pu être marquées comme lues. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final roles = ref.watch(sessionProvider)?.roles ?? const <AppRole>{};
    final async = ref.watch(alertsProvider);
    final alerts = async.value ?? const <AppAlert>[];
    final unread = alerts.where((a) => a.unread).length;
    final shown = _unreadOnly ? alerts.where((a) => a.unread).toList() : alerts;

    final List<Widget> content;
    if (async.isLoading && !async.hasValue) {
      content = const [SizedBox(height: 40), Center(child: CircularProgressIndicator(color: ParcColors.primary))];
    } else if (async.hasError && !async.hasValue) {
      content = [
        const ParcErrorAlert(message: 'Impossible de charger vos alertes.'),
        const SizedBox(height: 12),
        ParcOutlinedButton(label: 'Réessayer', height: 46, onPressed: () => ref.invalidate(alertsProvider)),
      ];
    } else if (shown.isEmpty) {
      content = [_Empty(unreadOnly: _unreadOnly)];
    } else {
      final groups = <String, List<AppAlert>>{};
      for (final a in shown) {
        groups.putIfAbsent(_groupOf(a.createdAt, now), () => []).add(a);
      }
      content = [
        if (_error != null) ...[ParcErrorAlert(message: _error!), const SizedBox(height: 10)],
        for (final (gi, entry) in groups.entries.indexed) ...[
          Padding(padding: EdgeInsets.only(top: gi == 0 ? 8 : 18, bottom: 4), child: SectionCaps(entry.key)),
          for (final a in entry.value) ...[
            const SizedBox(height: 10),
            _AlertTile(alert: a, time: _timeOf(a.createdAt, now), onTap: () => a.unread ? _markRead([a]) : null),
          ],
        ],
      ];
    }

    return Scaffold(
      backgroundColor: ParcColors.background,
      body: Column(
        children: [
          _Header(
            unread: unread,
            unreadOnly: _unreadOnly,
            onFilter: (v) => setState(() => _unreadOnly = v),
            onMarkAll: unread == 0 ? null : () => _markRead(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: ParcColors.primary,
              onRefresh: () => ref.refresh(alertsProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: roles.contains(AppRole.chauffeur)
          ? const ChauffeurBottomNav(currentIndex: 2)
          : const DemandeurBottomNav(currentIndex: 2),
    );
  }

  static String _groupOf(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return 'Plus anciennes';
  }

  static String _timeOf(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    return diff <= 1 ? FrenchDates.time(d) : FrenchDates.dayMonthShort(d);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unread, required this.unreadOnly, required this.onFilter, required this.onMarkAll});

  final int unread;
  final bool unreadOnly;
  final ValueChanged<bool> onFilter;
  final VoidCallback? onMarkAll;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Alertes', style: parcText(22, weight: 800, color: ParcColors.surface))),
                    Text(
                      unread == 0 ? 'Tout est lu' : '$unread non lue${unread > 1 ? 's' : ''}',
                      style: parcText(13, color: ParcColors.onDarkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                enabled: onMarkAll != null,
                child: Material(
                  color: ParcColors.headerChip,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onMarkAll,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'Tout marquer comme lu',
                            style: parcText(13, weight: 700, color: onMarkAll == null ? ParcColors.switchOff : ParcColors.surface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedChoice(
            onDark: true,
            labels: ['Toutes', 'Non lues ($unread)'],
            selected: unreadOnly ? 1 : 0,
            selectedColors: const [ParcColors.primary, ParcColors.primary],
            onChanged: (i) => onFilter(i == 1),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.time, required this.onTap});

  final AppAlert alert;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = alert;
    final (String icon, Color iconBg, Color iconFg) = switch (a.kind) {
      AlertKind.mission => (ParcIcons.car, ParcColors.primarySoft, ParcColors.primary),
      AlertKind.reminder => (ParcIcons.clock, ParcColors.pendingBg, ParcColors.pendingText),
      AlertKind.warning => (ParcIcons.warning, ParcColors.dangerSoft, ParcColors.danger),
    };
    final read = !a.unread;
    return Semantics(
      button: true,
      label: read ? null : 'Non lue',
      child: Material(
        color: read ? ParcColors.background : ParcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: read ? ParcColors.dividerSoft : ParcColors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: ParcIcon(icon, size: 20, color: iconFg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(a.title, style: parcText(14, weight: read ? 600 : 800))),
                          const SizedBox(width: 8),
                          Text(time, style: parcText(12, weight: 600, color: ParcColors.textMuted)),
                        ],
                      ),
                      if (a.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(a.message, style: parcText(13, color: ParcColors.textSecondary, height: 1.45)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: read ? Colors.transparent : ParcColors.accent, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.unreadOnly});

  final bool unreadOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: ParcColors.primarySoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const ParcIcon(ParcIcons.bell, size: 34, color: ParcColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            unreadOnly ? 'Aucune alerte non lue' : 'Aucune alerte pour le moment',
            textAlign: TextAlign.center,
            style: parcText(17, weight: 800),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous serez prévenu ici des missions et des échéances.',
            textAlign: TextAlign.center,
            style: parcText(14, color: ParcColors.textMuted),
          ),
        ],
      ),
    );
  }
}
