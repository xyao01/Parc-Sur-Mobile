import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/offline/local_store.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/data/ticket_camera.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';
import 'fuel_entry_test.dart' show FakeTicketCamera, duringMission, tapText;

const interruptedNote = 'Le véhicule est immobilisé : le gestionnaire est averti et vous recontacte.';

Future<void> openMission(
  WidgetTester tester,
  FakeMissionsGateway gateway, {
  LocalStore? store,
  Stream<bool>? online,
}) =>
    pumpApp(
      tester,
      location: '/missions/m-142/en-cours',
      now: duringMission,
      missions: gateway,
      store: store,
      online: online,
      overrides: [ticketCameraProvider.overrideWithValue(FakeTicketCamera())],
    );

Future<void> takePhoto(WidgetTester tester) async {
  final button = find.bySemanticsLabel('Prendre une photo');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  FakeMissionsGateway gateway() => FakeMissionsGateway(rows: inProgressRows(duringMission));

  group('Mob-C07 · signaler un incident (sinistre)', () {
    testWidgets('uploads the photos, then reports the incident on the mission', (tester) async {
      final g = gateway();
      await openMission(tester, g);
      await tapText(tester, 'Signaler un incident');
      await tapText(tester, 'Crevaison');
      await tester.enterText(find.byType(EditableText), 'Pneu avant droit');
      await takePhoto(tester);
      expect(find.text('Photo 1'), findsOneWidget);
      final fetches = g.fetches;
      await tapText(tester, "Envoyer l'incident");
      expect(g.fetches, greaterThan(fetches), reason: 'mission reloaded: the closure recap lists the incident');

      final incident = g.missionIncidents.single;
      final id = incident['id'] as String;
      expect(g.uploads, [
        {'local': '/tickets/t1.jpg', 'remote': 'sinistres/$id/1-photo.jpg'},
      ]);
      expect(incident, containsPair('missionId', 'm-142'));
      expect(incident, containsPair('kind', 'Crevaison'));
      expect(incident, containsPair('description', 'Pneu avant droit'));
      expect(incident, containsPair('serious', false));
      expect(incident['photos'], ['sinistres/$id/1-photo.jpg']);
      expect(incident['enteredAt'], duringMission);

      expect(find.text('Incident envoyé'), findsOneWidget);
      expect(find.text('Le gestionnaire est averti. Vous pouvez poursuivre la mission.'), findsOneWidget);
      await tapText(tester, 'Reprendre la mission');
      expect(find.text('Mission en cours'), findsOneWidget);
      expect(find.text('Ajouter un plein'), findsOneWidget);
    });

    testWidgets('two photos at most', (tester) async {
      await openMission(tester, gateway());
      await tapText(tester, 'Signaler un incident');
      await takePhoto(tester);
      await takePhoto(tester);
      expect(find.text('Photo 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Prendre une photo'), findsNothing);
    });

    testWidgets('a serious incident interrupts the mission', (tester) async {
      final g = gateway();
      await openMission(tester, g);
      await tapText(tester, 'Signaler un incident');
      await tapText(tester, 'Panne');
      await tapText(tester, 'Incident grave : le véhicule ne peut pas continuer');
      await tapText(tester, "Envoyer l'incident");

      expect(g.missionIncidents.single, containsPair('serious', true));
      expect(
        find.text('Le gestionnaire est averti. Le véhicule est immobilisé : ne reprenez pas la route et attendez ses instructions.'),
        findsOneWidget,
      );
      await tapText(tester, 'Fermer');

      expect(find.text('Mission interrompue'), findsWidgets);
      expect(find.textContaining('Incident « Panne » signalé à 09:16.'), findsOneWidget);
      expect(find.textContaining(interruptedNote), findsOneWidget);
      expect(find.text('Faire le contrôle de retour'), findsOneWidget);
      expect(find.text('Je suis arrivé à destination'), findsNothing);
      expect(find.text('Ajouter un plein'), findsNothing);
      expect(find.text('Signaler un incident'), findsNothing);
    });

    testWidgets('a mission interrupted on the server opens as interrupted', (tester) async {
      final rows = inProgressRows(duringMission);
      rows.single['incidentGrave'] = {
        'id': 's-1',
        'nature': 'Accident',
        'signaleLe': DateTime(2026, 11, 3, 8, 40).toUtc().toIso8601String(),
      };
      await openMission(tester, FakeMissionsGateway(rows: rows));
      expect(find.textContaining('Incident « Accident » signalé à 08:40.'), findsOneWidget);
      expect(find.text('Faire le contrôle de retour'), findsOneWidget);
    });

    testWidgets('a refusal of the server is shown', (tester) async {
      final g = gateway()..incidentError = const MissionsGatewayException('La mission D-0142 est terminée.');
      await openMission(tester, g);
      await tapText(tester, 'Signaler un incident');
      await tapText(tester, 'Retard');
      await tapText(tester, "Envoyer l'incident");
      expect(find.text('La mission D-0142 est terminée.'), findsOneWidget);
      expect(find.text('Incident envoyé'), findsNothing);
    });

    testWidgets('without network: kept on the phone, the mission shows as interrupted, sent when the network is back',
        (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      online.add(false);
      final store = MemoryStore();
      final g = gateway()..uploadError = const MissionsGatewayException('Connexion impossible.', network: true);
      await openMission(tester, g, store: store, online: online.stream);
      await tapText(tester, 'Signaler un incident');
      await tapText(tester, 'Accident');
      await tapText(tester, 'Incident grave : le véhicule ne peut pas continuer');
      await takePhoto(tester);
      await tapText(tester, "Envoyer l'incident");

      expect(find.textContaining('Enregistré sur le téléphone : il sera envoyé dès le retour du réseau.'), findsOneWidget);
      final pending = jsonDecode(store.read('outbox.pending.v1')!) as List;
      expect(pending.single, containsPair('kind', 'incident'));
      expect((pending.single as Map)['payload'], containsPair('photos', ['/tickets/t1.jpg']));
      await tapText(tester, 'Fermer');
      expect(find.textContaining('Incident « Accident » signalé à 09:16.'), findsOneWidget);

      expect(g.missionIncidents, isEmpty);
      g.uploadError = null;
      online.add(true);
      await tester.pumpAndSettle();

      expect(g.uploads.single['local'], '/tickets/t1.jpg');
      expect(g.missionIncidents.single, containsPair('kind', 'Accident'));
      expect(jsonDecode(store.read('outbox.pending.v1')!), isEmpty);
    });
  });
}
