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

/// Request awaiting the driver's answer (Mob-C01…C04): D-0142 to Bouaké.
List<Map<String, dynamic>> prototypePendingRows(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String at(int day, int h, [int m = 0]) => today.add(Duration(days: day, hours: h, minutes: m)).toUtc().toIso8601String();
  return [
    {
      'id': 'm-142',
      'numero': 'D-0142',
      'destination': 'Bouaké',
      'motif': 'Inspection de dépôts pétroliers',
      'commentaire': 'matériel de contrôle à transporter (2 caisses).',
      'depart': at(2, 7),
      'retour': at(4, 18),
      'passagers': 3,
      'demandeur': 'Koffi Ouattara',
      'telephoneDemandeur': '+225 07 00 00 00',
      'vehicule': {'id': 'v-4', 'nom': 'Toyota Prado', 'immatriculation': '3302 EA 01', 'kilometrage': 61452},
      'recueLe': at(0, 8, 12),
      'controleDepart': null,
      'controleRetour': null,
    },
  ];
}

/// D-0142 under way: departure check recorded today at 07:02 with 61 480 km.
List<Map<String, dynamic>> inProgressRows(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String at(int day, int h, [int m = 0]) => today.add(Duration(days: day, hours: h, minutes: m)).toUtc().toIso8601String();
  final row = Map<String, dynamic>.from(prototypePendingRows(now).single)
    ..remove('recueLe')
    ..['depart'] = at(0, 7)
    ..['retour'] = at(2, 18)
    ..['controleDepart'] = {'id': 'c-1', 'saisiLe': at(0, 7, 2), 'kilometrage': 61480};
  return [row];
}

class FakeMissionsGateway implements MissionsGateway {
  FakeMissionsGateway({this.rows, this.pending, this.fetchError, this.recordError, this.actionError});

  List<Map<String, dynamic>>? rows;
  List<Map<String, dynamic>>? pending;
  Object? fetchError;
  Object? recordError;

  /// Error of the actions with no backend yet (answer, incident). Null = accepted.
  Object? actionError;

  final recorded = <Map<String, dynamic>>[];
  final responses = <Map<String, dynamic>>[];
  final incidents = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> myMissions() async {
    if (fetchError != null) throw fetchError!;
    return rows ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> pendingRequests() async => pending ?? const [];

  @override
  Future<void> respondToRequest({required String missionId, required bool accept, String? reason, String? details}) async {
    if (actionError != null) throw actionError!;
    responses.add({'missionId': missionId, 'accept': accept, 'reason': reason, 'details': details});
  }

  @override
  Future<void> reportIncident({
    required String missionId,
    required String kind,
    String? description,
    required bool blocksDeparture,
  }) async {
    if (actionError != null) throw actionError!;
    incidents.add({'missionId': missionId, 'kind': kind, 'description': description, 'blocks': blocksDeparture});
  }

  /// Fill-ups (`saisir_plein_chauffeur`) and ticket uploads.
  final fuels = <Map<String, dynamic>>[];
  final uploads = <Map<String, String>>[];
  Object? fuelError;
  Object? uploadError;

  @override
  Future<void> uploadTicket({required String localPath, required String remotePath}) async {
    if (uploadError != null) throw uploadError!;
    uploads.add({'local': localPath, 'remote': remotePath});
  }

  @override
  Future<void> recordFuel({
    required String id,
    required String missionId,
    required int odometerKm,
    required double litres,
    required int amount,
    required bool full,
    String? station,
    required List<String> tickets,
    required DateTime enteredAt,
  }) async {
    if (fuelError != null) throw fuelError!;
    fuels.add({
      'id': id,
      'missionId': missionId,
      'km': odometerKm,
      'litres': litres,
      'amount': amount,
      'full': full,
      'station': station,
      'tickets': tickets,
      'enteredAt': enteredAt,
    });
  }

  @override
  Future<void> recordControl({
    required String id,
    required String missionId,
    required String type,
    required int odometerKm,
    required String fuel,
    required Map<String, String> points,
    String? observations,
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
      'observations': observations,
      'enteredAt': enteredAt,
    });
    // The server records the check on the mission.
    final key = type == 'depart' ? 'controleDepart' : 'controleRetour';
    final check = {'id': id, 'saisiLe': enteredAt.toUtc().toIso8601String(), 'kilometrage': odometerKm};
    rows = [
      for (final r in rows ?? const <Map<String, dynamic>>[]) r['id'] == missionId ? {...r, key: check} : r,
    ];
  }
}
