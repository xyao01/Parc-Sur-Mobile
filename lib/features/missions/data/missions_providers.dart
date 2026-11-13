import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/offline/local_store.dart';
import '../../../core/offline/outbox.dart';
import '../domain/mission.dart';
import 'control_submitter.dart';
import '../domain/mission_drafts.dart';
import 'missions_gateway.dart';
import 'supabase_missions_gateway.dart';

final missionsGatewayProvider =
    Provider<MissionsGateway>((ref) => SupabaseMissionsGateway(Supabase.instance.client));

const _missionsCacheKey = 'cache.missions.v1';

/// Missions of the signed-in driver, sorted by departure. Refresh with `ref.invalidate`.
///
/// Offline (l2-mob-04): the last list received is used, and checks not sent yet are applied to it,
/// so a mission whose departure is kept on the phone already shows as under way.
final missionsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  final store = ref.watch(localStoreProvider);
  final pending = ref.watch(outboxProvider.select((s) => s.pending));
  List<Map<String, dynamic>> rows;
  try {
    rows = await ref.watch(missionsGatewayProvider).myMissions();
    await store.write(_missionsCacheKey, jsonEncode(rows));
  } on MissionsGatewayException catch (e) {
    final cached = store.read(_missionsCacheKey);
    if (!e.network || cached == null) rethrow;
    rows = [for (final r in jsonDecode(cached) as List) Map<String, dynamic>.from(r as Map)];
  }
  for (final item in pending.where((i) => i.kind == OutboxKind.control)) {
    final c = ControlEntry.fromJson(item.id, item.payload);
    final key = c.type == 'depart' ? 'controleDepart' : 'controleRetour';
    rows = [
      for (final r in rows)
        r['id'] == c.missionId && r[key] == null
            ? {...r, key: {'id': c.id, 'saisiLe': c.enteredAt.toUtc().toIso8601String(), 'kilometrage': c.odometerKm}}
            : r,
    ];
  }
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
