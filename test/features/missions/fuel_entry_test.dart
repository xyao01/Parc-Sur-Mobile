import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/offline/local_store.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/data/ticket_camera.dart';
import 'package:parc_sur_mobile/features/missions/presentation/fuel_entry_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/mission_in_progress_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

final duringMission = DateTime(2026, 11, 3, 9, 16);

class FakeTicketCamera implements TicketCamera {
  int taken = 0;

  @override
  Future<String?> take() async => '/tickets/t${++taken}.jpg';

  @override
  Future<void> discard(List<String> paths) async {}
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openFuelEntry(
  WidgetTester tester,
  FakeMissionsGateway gateway, {
  LocalStore? store,
  Stream<bool>? online,
}) async {
  await pumpApp(
    tester,
    location: '/missions/m-142/en-cours',
    now: duringMission,
    missions: gateway,
    store: store,
    online: online,
    overrides: [ticketCameraProvider.overrideWithValue(FakeTicketCamera())],
  );
  await tapText(tester, 'Ajouter un plein');
}

Future<void> fill(WidgetTester tester, {String km = '61735', String litres = '48,5', String amount = '42 680'}) async {
  await tester.enterText(find.byKey(const Key('fuel.odometer')), km);
  await tester.enterText(find.byKey(const Key('fuel.litres')), litres);
  await tester.enterText(find.byKey(const Key('fuel.amount')), amount);
  await tester.pumpAndSettle();
}

Future<void> takeTicket(WidgetTester tester) async {
  final button = find.bySemanticsLabel('Photographier le ticket');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  FakeMissionsGateway gateway() => FakeMissionsGateway(rows: inProgressRows(duringMission));

  group('Mob-C13 · ajouter un plein pendant la mission', () {
    testWidgets('« Ajouter un plein » opens the fuel entry of the mission', (tester) async {
      await openFuelEntry(tester, gateway());
      expect(find.byType(FuelEntryScreen), findsOneWidget);
      expect(
        find.text('Cohérent avec le départ de la mission (61 480 km)'),
        findsNothing,
        reason: 'no value typed yet',
      );
      expect(find.text('Ticket de caisse'), findsOneWidget);
      expect(find.text('1 à 2 photos. Le ticket est obligatoire.'), findsOneWidget);
    });

    testWidgets('warns on an odometer beyond 1 500 km a day since the departure (bug 19/11/2026)', (tester) async {
      await openFuelEntry(tester, gateway());
      await fill(tester, km: '452753026850');
      expect(
        find.text('Écart inhabituel : 452 752 965 370 km depuis le départ de la mission (61 480 km). Vérifiez le compteur.'),
        findsOneWidget,
      );
      expect(find.textContaining('Cohérent'), findsNothing);
    });

    testWidgets('uploads the ticket, then records the fill-up on the mission', (tester) async {
      final g = gateway();
      await openFuelEntry(tester, g);
      await fill(tester);
      expect(find.text('Cohérent avec le départ de la mission (61 480 km)'), findsOneWidget);
      await tapText(tester, 'Non, partiel');
      await tester.enterText(find.byKey(const Key('fuel.station')), 'Total Yamoussoukro');
      await takeTicket(tester);
      expect(find.text('Ticket 1'), findsOneWidget);
      await tapText(tester, 'Enregistrer le plein');

      final fuel = g.fuels.single;
      final id = fuel['id'] as String;
      expect(g.uploads, [
        {'local': '/tickets/t1.jpg', 'remote': 'carburant/$id/1-ticket.jpg'},
      ]);
      expect(fuel, containsPair('missionId', 'm-142'));
      expect(fuel, containsPair('km', 61735));
      expect(fuel, containsPair('litres', 48.5));
      expect(fuel, containsPair('amount', 42680));
      expect(fuel, containsPair('full', false));
      expect(fuel, containsPair('station', 'Total Yamoussoukro'));
      expect(fuel['tickets'], ['carburant/$id/1-ticket.jpg']);

      expect(find.text('Plein enregistré'), findsOneWidget);
      expect(find.text('48,5 L · 42 680 FCFA'), findsOneWidget);
      await tapText(tester, 'Reprendre la mission');
      expect(find.byType(MissionInProgressScreen), findsOneWidget);
    });

    testWidgets('the ticket is required', (tester) async {
      final g = gateway();
      await openFuelEntry(tester, g);
      await fill(tester);
      await tapText(tester, 'Enregistrer le plein');
      expect(find.text('Photographiez le ticket de caisse pour enregistrer le plein.'), findsOneWidget);
      expect(g.fuels, isEmpty);
      expect(g.uploads, isEmpty);
    });

    testWidgets('litres and amount are required', (tester) async {
      final g = gateway();
      await openFuelEntry(tester, g);
      await fill(tester, litres: '', amount: '');
      await takeTicket(tester);
      await tapText(tester, 'Enregistrer le plein');
      expect(find.text('Indiquez le nombre de litres.'), findsOneWidget);
      expect(g.fuels, isEmpty);
    });

    testWidgets('an odometer below the departure of the mission is refused', (tester) async {
      final g = gateway();
      await openFuelEntry(tester, g);
      await fill(tester, km: '61000');
      await takeTicket(tester);
      await tapText(tester, 'Enregistrer le plein');
      expect(
        find.text('Le kilométrage ne peut pas être inférieur au départ de la mission (61 480 km).'),
        findsOneWidget,
      );
      expect(g.fuels, isEmpty);
    });

    testWidgets('a refusal of the server is shown', (tester) async {
      final g = gateway()..fuelError = const MissionsGatewayException('La mission D-0142 est terminée.');
      await openFuelEntry(tester, g);
      await fill(tester);
      await takeTicket(tester);
      await tapText(tester, 'Enregistrer le plein');
      expect(find.text('La mission D-0142 est terminée.'), findsOneWidget);
      expect(find.text('Plein enregistré'), findsNothing);
    });

    testWidgets('without network: kept on the phone with its ticket, sent when the network is back', (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      online.add(false);
      final store = MemoryStore();
      final g = gateway()..uploadError = const MissionsGatewayException('Connexion impossible.', network: true);
      await openFuelEntry(tester, g, store: store, online: online.stream);
      await fill(tester);
      await takeTicket(tester);
      await tapText(tester, 'Enregistrer le plein');

      expect(find.text('Enregistré sur le téléphone : il sera envoyé dès le retour du réseau.'), findsOneWidget);
      expect(g.fuels, isEmpty);
      final pending = jsonDecode(store.read('outbox.pending.v1')!) as List;
      expect(pending.single, containsPair('kind', 'plein'));
      expect((pending.single as Map)['payload'], containsPair('tickets', ['/tickets/t1.jpg']));

      g.uploadError = null;
      online.add(true);
      await tester.pumpAndSettle();

      expect(g.uploads.single['local'], '/tickets/t1.jpg');
      expect(g.fuels.single, containsPair('km', 61735));
      expect(jsonDecode(store.read('outbox.pending.v1')!), isEmpty);
    });

    testWidgets('before the departure check, no fill-up can be entered', (tester) async {
      await pumpApp(
        tester,
        location: '/missions/m-139/plein',
        missions: FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow)),
        overrides: [ticketCameraProvider.overrideWithValue(FakeTicketCamera())],
      );
      expect(find.text('Un plein se saisit pendant la mission, après le contrôle de départ.'), findsOneWidget);
      expect(find.text('Enregistrer le plein'), findsNothing);
    });
  });
}
