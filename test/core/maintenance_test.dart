import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/core/features.dart';
import 'package:parc_sur_mobile/core/widgets/maintenance_screen.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';

import '../helpers/fake_missions_gateway.dart';
import '../helpers/pump_app.dart';

/// Production flags: every view without backend opens « Page en maintenance »; views whose migration is applied open.
const production = Features();

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void expectMaintenance(String feature) {
  expect(find.byType(MaintenanceScreen), findsOneWidget);
  expect(find.text('Page en maintenance'), findsOneWidget);
  expect(find.text('Cette fonctionnalité n’est pas encore disponible. Revenez bientôt.'), findsOneWidget);
  expect(find.text(feature), findsOneWidget);
}

void main() {
  const requester = MobileProfile(firstName: 'Koffi', lastName: 'Ouattara', roles: {AppRole.demandeur});
  final duringMission = DateTime(2026, 11, 3, 9, 16);

  testWidgets('answer to a request (C02-C04)', (tester) async {
    await pumpApp(tester, location: '/missions/demandes/m-142', features: production);
    expectMaintenance('Réponse aux demandes');
  });

  testWidgets('« Je suis disponible » (C01) is hidden in production (demande du 20/11/2026)', (tester) async {
    await pumpApp(tester, location: '/missions', features: production);
    expect(find.text('Bonjour, Yao'), findsOneWidget);
    expect(find.text('Je suis disponible'), findsNothing);
    expect(find.bySemanticsLabel('Disponibilité'), findsNothing);
  });

  testWidgets('« Un problème : bloquer le départ » (C06)', (tester) async {
    await pumpApp(tester, location: '/missions/m-139/validation', features: production);
    await tapText(tester, 'Un problème : bloquer le départ');
    expectMaintenance('Bloquer le départ');
  });

  testWidgets('« Signaler un incident » (C07) is live in production', (tester) async {
    await pumpApp(
      tester,
      location: '/missions/m-142/en-cours',
      now: duringMission,
      features: production,
      missions: FakeMissionsGateway(rows: inProgressRows(duringMission)),
    );
    await tapText(tester, 'Signaler un incident');
    expect(find.byType(MaintenanceScreen), findsNothing);
  });

  testWidgets('photo button (C05)', (tester) async {
    await pumpApp(tester, location: '/missions/m-139/preparation', features: production);
    await tester.ensureVisible(find.bySemanticsLabel('Ajouter une photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajouter une photo'));
    await tester.pumpAndSettle();
    expectMaintenance('Photos');
  });

  testWidgets('expenses at closure (C10, l2-mis-02)', (tester) async {
    await pumpApp(
      tester,
      location: '/missions/m-142/cloture',
      now: duringMission,
      features: production,
      missions: FakeMissionsGateway(rows: inProgressRows(duringMission)),
    );
    await tapText(tester, 'Dépenses engagées (carburant, péage…)');
    expectMaintenance('Dépenses de la mission');
  });

  testWidgets('« Ajouter un plein » (C13) is live in production', (tester) async {
    await pumpApp(
      tester,
      location: '/missions/m-142/en-cours',
      now: duringMission,
      features: production,
      missions: FakeMissionsGateway(rows: inProgressRows(duringMission)),
    );
    await tapText(tester, 'Ajouter un plein');
    expect(find.byType(MaintenanceScreen), findsNothing);
  });

  testWidgets('« Signaler un problème » (D08) is live in production', (tester) async {
    await pumpApp(tester, location: '/demandes/m-139/suivi', profile: requester, features: production);
    await tapText(tester, 'Signaler un problème');
    expect(find.byType(MaintenanceScreen), findsNothing);
    expect(find.text('Envoyer au gestionnaire'), findsOneWidget);
  });

  testWidgets('evaluation (D10)', (tester) async {
    await pumpApp(tester, location: '/demandes/m-118/evaluation', profile: requester, features: production);
    expectMaintenance('Évaluation de la mission');
  });
}
