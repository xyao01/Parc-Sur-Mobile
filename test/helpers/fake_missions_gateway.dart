import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';

/// Rows shaped like `mes_missions_chauffeur()`, matching the prototype,
/// positioned relative to [now] (prototype: Tuesday 3 November 2026).
List<Map<String, dynamic>> prototypeMissionRows(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String at(int day, int h, [int m = 0]) => today.add(Duration(days: day, hours: h, minutes: m)).toUtc().toIso8601String();
  return [
    {
      'id': 'm-139',
      'numero': 'D-0139',
      'destination': 'Yamoussoukro',
      'motif': 'Inspection',
      'depart': at(0, 7, 30),
      'retour': at(1, 17),
      'passagers': 2,
      'demandeur': 'Koffi Ouattara',
      'vehicule': {'id': 'v-1', 'nom': 'Land Cruiser', 'immatriculation': '1150 FB 01', 'kilometrage': 84112},
      'controleDepart': null,
      'controleRetour': null,
    },
    {
      'id': 'm-144',
      'numero': 'D-0144',
      'destination': 'Abengourou',
      'depart': at(3, 6),
      'retour': at(4, 18),
      'passagers': 1,
      'demandeur': 'Aya Konan',
      'vehicule': {'id': 'v-2', 'nom': 'Toyota Prado', 'immatriculation': '2087 FC 01', 'kilometrage': 51000},
      'controleDepart': null,
      'controleRetour': null,
    },
    {
      'id': 'm-151',
      'numero': 'D-0151',
      'destination': 'Korhogo',
      'depart': at(7, 6),
      'retour': at(10, 17),
      'passagers': 3,
      'demandeur': 'Koffi Ouattara',
      'vehicule': {'id': 'v-3', 'nom': 'Hilux', 'immatriculation': '3321 FD 01', 'kilometrage': 12000},
      'controleDepart': null,
      'controleRetour': null,
    },
  ];
}

class FakeMissionsGateway implements MissionsGateway {
  FakeMissionsGateway({this.rows, this.fetchError, this.recordError});

  List<Map<String, dynamic>>? rows;
  Object? fetchError;
  Object? recordError;
  final recorded = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> myMissions() async {
    if (fetchError != null) throw fetchError!;
    return rows ?? const [];
  }

  @override
  Future<void> recordControl({
    required String id,
    required String missionId,
    required String type,
    required int odometerKm,
    required String fuel,
    required Map<String, String> points,
    required DateTime enteredAt,
  }) async {
    if (recordError != null) throw recordError!;
    recorded.add({
      'id': id,
      'missionId': missionId,
      'type': type,
      'km': odometerKm,
      'fuel': fuel,
      'points': points,
    });
    // The server marks the mission's departure check as done.
    rows = [
      for (final r in rows ?? const <Map<String, dynamic>>[])
        r['id'] == missionId ? {...r, 'controleDepart': {'id': id, 'kilometrage': odometerKm}} : r,
    ];
  }
}
