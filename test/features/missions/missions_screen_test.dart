import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/presentation/departure_check_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the missions from Supabase like the prototype', (tester) async {
    await pumpApp(tester, location: '/missions');

    expect(find.text('Bonjour, Yao'), findsOneWidget);
    expect(find.text('YK'), findsOneWidget);
    expect(find.text("Mardi 3 novembre · 1 mission aujourd'hui"), findsOneWidget);
    expect(find.text('MISSION DU JOUR'), findsOneWidget);
    expect(find.text('Départ à 07:30'), findsOneWidget);
    expect(find.text('D-0139'), findsOneWidget);
    expect(find.text('Yamoussoukro'), findsOneWidget);
    expect(find.text('Land Cruiser · 1150 FB 01'), findsOneWidget);
    expect(find.text('Mer. 4 nov. · 17:00'), findsOneWidget);
    expect(find.text('Koffi Ouattara'), findsOneWidget);

    expect(find.text('À VENIR'), findsOneWidget);
    expect(find.text('VEN.'), findsOneWidget);
    expect(find.text('Abengourou'), findsOneWidget);
    expect(find.text('Toyota Prado · 06:00 → sam. 18:00'), findsOneWidget);
    expect(find.text('MAR.'), findsOneWidget);
    expect(find.text('Hilux · 06:00 → ven. 17:00'), findsOneWidget);

    expect(find.text('Saisir un plein'), findsOneWidget);
    expect(find.text('Signaler un incident'), findsOneWidget);
    for (final tab in ['Missions', 'Planning', 'Alertes', 'Profil']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Commencer le contrôle de départ" opens the departure check', (tester) async {
    await pumpApp(tester, location: '/missions');

    await tester.tap(find.text('Commencer le contrôle de départ'));
    await tester.pumpAndSettle();
    expect(find.byType(DepartureCheckScreen), findsOneWidget);
  });

  testWidgets('no departure check button once the check is recorded', (tester) async {
    final rows = prototypeMissionRows(prototypeNow);
    rows[0] = {...rows[0], 'controleDepart': {'id': 'c-1', 'kilometrage': 84230}};
    await pumpApp(tester, location: '/missions', missions: FakeMissionsGateway(rows: rows));

    expect(find.text('Commencer le contrôle de départ'), findsNothing);
  });

  testWidgets('says when there is no mission today', (tester) async {
    await pumpApp(tester, location: '/missions', missions: FakeMissionsGateway(rows: []));

    expect(find.text("Mardi 3 novembre · 0 mission aujourd'hui"), findsOneWidget);
    expect(find.text("Aucune mission aujourd'hui."), findsOneWidget);
  });

  testWidgets('shows an error and retries when missions cannot be loaded', (tester) async {
    final gateway = FakeMissionsGateway(fetchError: Exception('offline'));
    await pumpApp(tester, location: '/missions', missions: gateway);

    expect(find.text('Impossible de charger vos missions.'), findsOneWidget);
    gateway
      ..fetchError = null
      ..rows = prototypeMissionRows(prototypeNow);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('D-0139'), findsOneWidget);
  });
}
