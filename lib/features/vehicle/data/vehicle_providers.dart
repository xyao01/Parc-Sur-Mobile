import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/offline/local_store.dart';
import '../../../core/offline/outbox.dart';
import '../../auth/application/session.dart';
import '../domain/assigned_vehicle.dart';
import 'supabase_vehicle_gateway.dart';
import 'vehicle_gateway.dart';

final vehicleGatewayProvider = Provider<VehicleGateway>((ref) => SupabaseVehicleGateway(Supabase.instance.client));

const _cacheKey = 'cache.mon_vehicule.v1';

/// Vehicles assigned to the signed-in agent (empty when none). Offline: last list received,
/// with the month marked done when a reading of this month is kept on the phone.
final myVehiclesProvider = FutureProvider.autoDispose<List<AssignedVehicle>>((ref) async {
  final profile = ref.watch(sessionProvider);
  if (profile == null || !profile.hasAssignedVehicle) return const [];
  final store = ref.watch(localStoreProvider);
  final pending = ref.watch(outboxProvider.select((s) => s.pending));
  List<Map<String, dynamic>> rows;
  try {
    rows = await ref.watch(vehicleGatewayProvider).myVehicles();
    await store.write(_cacheKey, jsonEncode(rows));
  } on VehicleGatewayException catch (e) {
    final cached = store.read(_cacheKey);
    if (!e.network || cached == null) rethrow;
    rows = [for (final r in jsonDecode(cached) as List) Map<String, dynamic>.from(r as Map)];
  }
  final queued = {
    for (final i in pending)
      if (i.kind == OutboxKind.monthlyReading) i.payload['vehicleId'] as String,
  };
  return [
    for (final r in rows)
      AssignedVehicle.fromJson(
        queued.contains(r['id']) ? {...r, 'moisCourant': {...?(r['moisCourant'] as Map?), 'saisi': true}} : r,
      ),
  ];
});

/// A monthly reading (`saisir_releve_mensuel`), sent now or kept on the phone.
class MonthlyReading {
  const MonthlyReading({required this.id, required this.vehicleId, required this.odometerKm, required this.date});

  factory MonthlyReading.fromJson(String id, Map<String, dynamic> j) => MonthlyReading(
        id: id,
        vehicleId: j['vehicleId'] as String,
        odometerKm: (j['km'] as num).toInt(),
        date: DateTime.parse(j['date'] as String),
      );

  final String id;
  final String vehicleId;
  final int odometerKm;
  final DateTime date;

  Map<String, dynamic> toJson() => {'vehicleId': vehicleId, 'km': odometerKm, 'date': date.toIso8601String()};

  Future<Map<String, dynamic>> sendWith(VehicleGateway gateway) =>
      gateway.recordMonthly(id: id, vehicleId: vehicleId, odometerKm: odometerKm, date: date);
}
