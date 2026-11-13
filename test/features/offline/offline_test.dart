import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/core/offline/local_store.dart';
import 'package:parc_sur_mobile/features/auth/application/session.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/presentation/mission_in_progress_screen.dart';
import 'package:parc_sur_mobile/features/vehicle/data/vehicle_gateway.dart';
import 'package:parc_sur_mobile/features/vehicle/presentation/monthly_reading_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/fake_vehicle_gateway.dart';
import '../../helpers/pump_app.dart';

const offlineText = 'Hors connexion : la saisie sera envoyée dès le retour du réseau.';
const network = MissionsGatewayException('Connexion impossible.', network: true);

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// A departure check of D-0139 kept on the phone.
Map<String, dynamic> pendingDeparture() => {
      'id': 'c-local-1',
      'kind': 'controle',
      'payload': {
        'missionId': 'm-139',
        'type': 'depart',
        'km': 84230,
        'fuel': 'plein',
        'points': {'pneus': 'ok'},
        'observations': null,
        'enteredAt': DateTime(2026, 11, 3, 5, 50).toIso8601String(),
      },
      'createdAt': DateTime(2026, 11, 3, 5, 50).toIso8601String(),
    };

void main() {
  group('l2-mob-04 · saisie hors connexion', () {
    testWidgets('departure check without network: kept on the phone, mission under way, sent when back', (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      online.add(false);
      final store = MemoryStore();
      final gateway = FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow), recordError: network);
      await pumpApp(tester, location: '/missions/m-139/preparation', missions: gateway, store: store, online: online.stream);

      expect(find.text(offlineText), findsOneWidget);
      await tester.enterText(find.byKey(const Key('preparation.odometer')), '84230');
      await tapText(tester, 'Continuer vers la validation');
      await tapText(tester, 'Je confirme que le véhicule est prêt à partir et que les informations saisies sont exactes.');
      await tapText(tester, 'Valider et démarrer la mission');

      expect(find.byType(MissionInProgressScreen), findsOneWidget, reason: 'mission shown under way from the phone');
      expect(find.text(offlineText), findsOneWidget);
      expect(gateway.recorded, isEmpty);
      expect(store.read('outbox.pending.v1'), contains('m-139'), reason: 'kept if the app is closed');

      gateway.recordError = null;
      online.add(true);
      await tester.pumpAndSettle();

      expect(gateway.recorded.single, allOf(containsPair('missionId', 'm-139'), containsPair('type', 'depart')));
      expect(jsonDecode(store.read('outbox.pending.v1')!), isEmpty);
      expect(find.text(offlineText), findsNothing);
    });

    testWidgets('entries kept from a previous launch are sent at start', (tester) async {
      final store = MemoryStore()..values['outbox.pending.v1'] = jsonEncode([pendingDeparture()]);
      final gateway = FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow));
      await pumpApp(tester, location: '/missions', missions: gateway, store: store);

      expect(gateway.recorded.single, allOf(containsPair('id', 'c-local-1'), containsPair('km', 84230)));
      expect(find.text('1 saisie en attente d’envoi.'), findsNothing);
    });

    testWidgets('an entry refused by the server is reported, then dismissed', (tester) async {
      final store = MemoryStore()..values['outbox.pending.v1'] = jsonEncode([pendingDeparture()]);
      final gateway = FakeMissionsGateway(
        rows: prototypeMissionRows(prototypeNow),
        recordError: const MissionsGatewayException('Cette mission ne vous est pas attribuée.'),
      );
      await pumpApp(tester, location: '/missions', missions: gateway, store: store);

      expect(find.text('1 saisie refusée par le serveur : Cette mission ne vous est pas attribuée.'), findsOneWidget);
      await tapText(tester, 'OK');
      expect(find.textContaining('refusée par le serveur'), findsNothing);
    });

    testWidgets('missions stay visible without network (last list received)', (tester) async {
      final store = MemoryStore();
      await pumpApp(tester, location: '/missions', store: store);
      expect(find.text('Yamoussoukro'), findsOneWidget);

      await pumpApp(
        tester,
        location: '/planning',
        store: store,
        missions: FakeMissionsGateway(fetchError: network),
      );
      await tapText(tester, 'Missions');
      expect(find.text('Yamoussoukro'), findsOneWidget);
    });

    test('the signed-in profile is kept to reopen the session offline', () async {
      final store = MemoryStore();
      const profile = MobileProfile(
        firstName: 'Yao',
        lastName: 'Kouadio',
        email: 'y@k.ci',
        roles: {AppRole.chauffeur},
        hasAssignedVehicle: true,
      );
      await store.write('cache.profil.v1', jsonEncode(profile.toCache()));
      final back = cachedProfile(store)!;
      expect(back.fullName, 'Yao Kouadio');
      expect(back.roles, {AppRole.chauffeur});
      expect(back.email, 'y@k.ci');
      expect(back.hasAssignedVehicle, isTrue);
    });
  });

  group('l2-km-02 · relevé mensuel', () {
    const agent = MobileProfile(
      firstName: 'Koffi',
      lastName: 'Ouattara',
      roles: {AppRole.demandeur},
      hasAssignedVehicle: true,
    );

    testWidgets('the home asks for the reading, which is sent to saisir_releve_mensuel', (tester) async {
      final vehicles = FakeVehicleGateway(rows: prototypeVehicleRows());
      await pumpApp(tester, location: '/demandes', profile: agent, vehicles: vehicles);

      expect(find.text('Relevé mensuel à saisir'), findsOneWidget);
      expect(find.text('Toyota Corolla · 2214 FA 01'), findsOneWidget);
      await tapText(tester, 'Relevé mensuel à saisir');

      expect(find.byType(MonthlyReadingScreen), findsOneWidget);
      expect(find.text('Dernier relevé : 45 210 km le 31/10'), findsOneWidget);
      expect(find.text('DERNIERS RELEVÉS'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('monthly.odometer')), '46100');
      await tapText(tester, 'Enregistrer le relevé');

      expect(vehicles.recorded.single, allOf(containsPair('vehicleId', 'v-9'), containsPair('km', 46100)));
      expect(find.text('Relevé enregistré'), findsOneWidget);
      await tapText(tester, "Retour à l'accueil");
      expect(find.text('Relevé mensuel à saisir'), findsNothing);
    });

    testWidgets('without network the reading is kept on the phone', (tester) async {
      final vehicles = FakeVehicleGateway(
        rows: prototypeVehicleRows(),
        recordError: const VehicleGatewayException('Connexion impossible.', network: true),
      );
      final store = MemoryStore();
      await pumpApp(tester, location: '/mon-vehicule/v-9/releve', profile: agent, vehicles: vehicles, store: store);
      await tester.enterText(find.byKey(const Key('monthly.odometer')), '46100');
      await tapText(tester, 'Enregistrer le relevé');

      expect(find.text('Enregistré sur le téléphone : il sera envoyé dès le retour du réseau.'), findsOneWidget);
      expect(store.read('outbox.pending.v1'), contains('releve_mensuel'));
      expect(vehicles.recorded, isEmpty);
    });

    testWidgets('no assigned vehicle: no reading asked', (tester) async {
      await pumpApp(
        tester,
        location: '/demandes',
        profile: const MobileProfile(firstName: 'A', lastName: 'B', roles: {AppRole.demandeur}),
        vehicles: FakeVehicleGateway(rows: prototypeVehicleRows()),
      );
      expect(find.text('Relevé mensuel à saisir'), findsNothing);
    });
  });
}
