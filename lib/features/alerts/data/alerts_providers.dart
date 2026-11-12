import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_role.dart';
import '../../../core/clock.dart';
import '../../auth/application/session.dart';
import '../domain/app_alert.dart';
import 'alerts_gateway.dart';
import 'supabase_alerts_gateway.dart';

final alertsGatewayProvider = Provider<AlertsGateway>((ref) => SupabaseAlertsGateway(Supabase.instance.client));

/// Alerts of the signed-in user, newest first: the driver's (chauffeur role) and the
/// web account's (demandeur role). Each is read only for the roles the user has.
final alertsProvider = AsyncNotifierProvider.autoDispose<AlertsNotifier, List<AppAlert>>(AlertsNotifier.new);

/// Unread alerts, for the badges. 0 while loading or on error.
final unreadAlertsCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(alertsProvider).value?.where((a) => a.unread).length ?? 0,
);

class AlertsNotifier extends AsyncNotifier<List<AppAlert>> {
  @override
  Future<List<AppAlert>> build() async {
    final roles = ref.watch(sessionProvider)?.roles ?? const <AppRole>{};
    final gateway = ref.watch(alertsGatewayProvider);
    final results = await Future.wait([
      if (roles.contains(AppRole.chauffeur))
        gateway.driverAlerts().then((rows) => [for (final r in rows) AppAlert.fromJson(r, AlertAudience.driver)]),
      if (roles.contains(AppRole.demandeur))
        gateway.requesterAlerts().then((rows) => [for (final r in rows) AppAlert.fromJson(r, AlertAudience.requester)]),
    ]);
    return [for (final list in results) ...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Marks [alerts] as read (all unread ones when null) on the server, then in the list.
  /// Throws an `AlertsGatewayException` when refused.
  Future<void> markRead([List<AppAlert>? alerts]) async {
    final current = state.value ?? const <AppAlert>[];
    final targets = (alerts ?? current).where((a) => a.unread).toList();
    if (targets.isEmpty) return;
    final all = alerts == null;
    final gateway = ref.read(alertsGatewayProvider);
    final driver = [for (final a in targets) if (a.audience == AlertAudience.driver) a.id];
    final requester = [for (final a in targets) if (a.audience == AlertAudience.requester) a.id];
    await Future.wait([
      if (driver.isNotEmpty) gateway.markDriverAlertsRead(all ? null : driver),
      if (requester.isNotEmpty) gateway.markRequesterAlertsRead(all ? null : requester),
    ]);
    final now = ref.read(clockProvider)();
    final ids = {for (final a in targets) a.id};
    state = AsyncData([for (final a in current) ids.contains(a.id) ? a.markedRead(now) : a]);
  }
}
