import 'package:parc_sur_mobile/features/vehicle/data/vehicle_gateway.dart';

/// `mon_vehicule()` of an agent: one vehicle, reading of the month not done yet.
List<Map<String, dynamic>> prototypeVehicleRows() => [
      {
        'id': 'v-9',
        'nom': 'Toyota Corolla',
        'immatriculation': '2214 FA 01',
        'kilometrage': 45210,
        'releves': [
          {'date': '2026-10-31', 'kilometrage': 45210, 'source': 'mensuel', 'aVerifier': false, 'corrige': false},
          {'date': '2026-09-30', 'kilometrage': 43980, 'source': 'mensuel', 'aVerifier': false, 'corrige': false},
        ],
        'moisCourant': {'mois': '2026-11-01', 'saisi': false},
      },
    ];

class FakeVehicleGateway implements VehicleGateway {
  FakeVehicleGateway({this.rows, this.recordError, this.fetchError});

  List<Map<String, dynamic>>? rows;
  Object? recordError;
  Object? fetchError;
  final recorded = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> myVehicles() async {
    if (fetchError != null) throw fetchError!;
    return rows ?? const [];
  }

  @override
  Future<Map<String, dynamic>> recordMonthly({
    required String id,
    required String vehicleId,
    required int odometerKm,
    required DateTime date,
  }) async {
    if (recordError != null) throw recordError!;
    if (!recorded.any((r) => r['id'] == id)) {
      recorded.add({'id': id, 'vehicleId': vehicleId, 'km': odometerKm});
    }
    rows = [
      for (final r in rows ?? const <Map<String, dynamic>>[])
        r['id'] == vehicleId ? {...r, 'moisCourant': {'mois': '2026-11-01', 'saisi': true}} : r,
    ];
    return {'aVerifier': false};
  }
}
