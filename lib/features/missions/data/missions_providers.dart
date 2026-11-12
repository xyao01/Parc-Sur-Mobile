import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/mission.dart';
import '../domain/mission_drafts.dart';
import 'missions_gateway.dart';
import 'supabase_missions_gateway.dart';

final missionsGatewayProvider =
    Provider<MissionsGateway>((ref) => SupabaseMissionsGateway(Supabase.instance.client));

/// Missions of the signed-in driver, sorted by departure. Refresh with `ref.invalidate`.
final missionsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  final rows = await ref.watch(missionsGatewayProvider).myMissions();
  return [for (final row in rows) Mission.fromJson(row)]..sort((a, b) => a.departure.compareTo(b.departure));
});

/// Requests waiting for the driver's answer (always empty with the current database).
final pendingRequestsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  final rows = await ref.watch(missionsGatewayProvider).pendingRequests();
  return [for (final row in rows) Mission.fromJson(row)];
});

/// A mission of the driver, or a pending request, by id.
final missionByIdProvider = Provider.autoDispose.family<AsyncValue<Mission?>, String>((ref, id) {
  Mission? find(List<Mission> list) {
    for (final m in list) {
      if (m.id == id) return m;
    }
    return null;
  }

  final missions = ref.watch(missionsProvider);
  final pending = ref.watch(pendingRequestsProvider);
  final found = find(missions.value ?? const []) ?? find(pending.value ?? const []);
  if (found != null) return AsyncData(found);
  if (missions.isLoading || pending.isLoading) return const AsyncLoading();
  if (missions.hasError) return AsyncError(missions.error!, missions.stackTrace!);
  return const AsyncData(null);
});

/// Departure entries of a mission, kept from Mob-C05 to Mob-C06.
final departureDraftProvider = Provider.family<DepartureDraft, String>((ref, id) => DepartureDraft());

/// Return entries of a mission, kept from Mob-C08 to Mob-C10.
final returnDraftProvider = Provider.family<ReturnDraft, String>((ref, id) => ReturnDraft());
