import 'package:parc_sur_mobile/features/requests/data/requests_gateway.dart';

/// Rows shaped like `demande_vue`, matching the prototype Mob-D01…D10, relative to [now]
/// (prototype: Tuesday 3 November 2026, 06:00). Newest first.
List<Map<String, dynamic>> prototypeRequestRows(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String at(int day, int h, [int m = 0]) => today.add(Duration(days: day, hours: h, minutes: m)).toUtc().toIso8601String();
  Map<String, dynamic> row(String id, String number, String destination, String status, String depart, String retour,
          {int passengers = 3, String created = '', String? vehicle, String? driver, String? refusal, String? notes}) =>
      {
        'id': id,
        'numero': number,
        'demandeur_id': 'u-1',
        'motif': 'Inspection de dépôts pétroliers',
        'destination': destination,
        'depart': depart,
        'retour': retour,
        'passagers': passengers,
        'avec_chauffeur': true,
        'commentaire': notes,
        'statut': status,
        'vehicule': vehicle,
        'chauffeur': driver,
        'motif_refus': refusal,
        'motif_annulation': null,
        'decide_le': null,
        'created_at': created,
      };
  return [
    row('m-142', 'D-0142', 'Bouaké', 'attente', at(2, 7), at(4, 18),
        created: at(0, 5, 5), notes: 'matériel de contrôle à transporter (2 caisses).'),
    row('m-139', 'D-0139', 'Yamoussoukro', 'validee', at(0, 5, 30), at(1, 17),
        passengers: 2, created: at(-2, 9), vehicle: 'Land Cruiser · 1150 FB 01', driver: 'Yao Kouadio'),
    row('m-140', 'D-0140', 'Abengourou', 'validee', at(3, 6), at(4, 18),
        passengers: 1, created: at(-3, 9), vehicle: 'Toyota Prado · 2087 FC 01', driver: 'Aya Koné'),
    row('m-131', 'D-0131', 'San-Pédro', 'refusee', at(5, 7), at(6, 18),
        created: at(-5, 9), refusal: 'Aucun véhicule disponible à ces dates'),
    row('m-118', 'D-0118', 'Daloa', 'validee', at(-22, 7), at(-21, 18),
        passengers: 2, created: at(-25, 9), vehicle: 'Hilux · 3321 FD 01', driver: 'Yao Kouadio'),
  ];
}

class FakeRequestsGateway implements RequestsGateway {
  FakeRequestsGateway({this.rows, this.error});

  List<Map<String, dynamic>>? rows;
  Object? error;

  final created = <Map<String, dynamic>>[];
  final updated = <String, Map<String, dynamic>>{};
  final cancelled = <(String, String)>[];
  final problems = <Map<String, dynamic>>[];

  /// Report ids of every call, refused ones included.
  final problemAttempts = <String>[];
  final ratings = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> myRequests() async {
    if (error != null) throw error!;
    return rows ?? const [];
  }

  @override
  Future<String> create(Map<String, dynamic> row) async {
    if (error != null) throw error!;
    created.add(row);
    const id = 'm-150';
    rows = [
      {
        ...row,
        'id': id,
        'numero': 'D-0150',
        'demandeur_id': 'u-1',
        'statut': 'attente',
        'created_at': DateTime(2026, 11, 3, 6).toUtc().toIso8601String(),
      },
      ...?rows,
    ];
    return id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> row) async {
    if (error != null) throw error!;
    updated[id] = row;
    rows = [for (final r in rows ?? const <Map<String, dynamic>>[]) r['id'] == id ? {...r, ...row} : r];
  }

  @override
  Future<void> cancel(String id, String reason) async {
    if (error != null) throw error!;
    cancelled.add((id, reason));
    rows = [
      for (final r in rows ?? const <Map<String, dynamic>>[])
        r['id'] == id ? {...r, 'statut': 'annulee', 'motif_annulation': reason} : r,
    ];
  }

  @override
  Future<void> reportProblem({required String id, required String requestId, required String kind, String? description}) async {
    problemAttempts.add(id);
    if (error != null) throw error!;
    problems.add({'id': id, 'requestId': requestId, 'kind': kind, 'description': description});
  }

  @override
  Future<void> rate({required String requestId, required int rating, required List<String> tags, String? comment}) async {
    if (error != null) throw error!;
    ratings.add({'id': requestId, 'rating': rating, 'tags': tags, 'comment': comment});
  }
}
