import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/mission.dart';
import 'missions_gateway.dart';
import 'supabase_missions_gateway.dart';

final missionsGatewayProvider =
    Provider<MissionsGateway>((ref) => SupabaseMissionsGateway(Supabase.instance.client));

/// Missions of the signed-in driver, sorted by departure. Refresh with `ref.invalidate`.
final missionsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  final rows = await ref.watch(missionsGatewayProvider).myMissions();
  return [for (final row in rows) Mission.fromJson(row)]..sort((a, b) => a.departure.compareTo(b.departure));
});

final missionByIdProvider = Provider.autoDispose.family<AsyncValue<Mission?>, String>((ref, id) {
  return ref.watch(missionsProvider).whenData((missions) {
    for (final m in missions) {
      if (m.id == id) return m;
    }
    return null;
  });
});
