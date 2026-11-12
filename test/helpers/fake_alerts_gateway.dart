import 'package:parc_sur_mobile/features/alerts/data/alerts_gateway.dart';

/// Driver alerts of the validated prototype Mob-C12, relative to [now]
/// (prototype: Tuesday 3 November 2026): 3 unread, 1 read.
List<Map<String, dynamic>> prototypeDriverAlerts(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String at(int day, int h, [int m = 0]) => today.add(Duration(days: day, hours: h, minutes: m)).toUtc().toIso8601String();
  return [
    {
      'id': 'a-1',
      'titre': 'Rappel : mission D-0142 demain',
      'message': 'Départ jeudi 5 novembre à 07:00 pour Bouaké avec le Toyota Prado 3302 EA 01.',
      'lien': null,
      'creeLe': at(0, 5, 30),
      'lueLe': null,
    },
    {
      'id': 'a-2',
      'titre': 'Mission D-0142 attribuée',
      'message': 'Abidjan → Bouaké, du jeudi 5 au samedi 7 novembre. Demandeur : Koffi Ouattara.',
      'lien': null,
      'creeLe': at(0, 5, 12),
      'lueLe': null,
    },
    {
      'id': 'a-3',
      'titre': 'Échéance à J-30',
      'message': 'Le permis de conduire arrive à échéance le 4 décembre. Pensez à le renouveler.',
      'lien': null,
      'creeLe': at(-1, 17, 40),
      'lueLe': null,
    },
    {
      'id': 'a-4',
      'titre': 'Mission D-0131 attribuée',
      'message': 'Abidjan → San-Pédro, le lundi 2 novembre. Demandeur : Aya Konan.',
      'lien': null,
      'creeLe': at(-4, 9),
      'lueLe': at(-4, 10),
    },
  ];
}

class FakeAlertsGateway implements AlertsGateway {
  FakeAlertsGateway({this.driver, this.requester, this.error});

  List<Map<String, dynamic>>? driver;
  List<Map<String, dynamic>>? requester;
  Object? error;

  int driverFetches = 0;
  int requesterFetches = 0;
  final markedDriver = <List<String>?>[];
  final markedRequester = <List<String>?>[];

  @override
  Future<List<Map<String, dynamic>>> driverAlerts() async {
    driverFetches++;
    if (error != null) throw error!;
    return driver ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> requesterAlerts() async {
    requesterFetches++;
    if (error != null) throw error!;
    return requester ?? const [];
  }

  @override
  Future<void> markDriverAlertsRead(List<String>? ids) async => markedDriver.add(ids);

  @override
  Future<void> markRequesterAlertsRead(List<String>? ids) async => markedRequester.add(ids);
}
