import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/presentation/departure_preparation_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/mission_in_progress_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/planning_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  FakeMissionsGateway gateway() => FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow));

  testWidgets('the Planning tab opens the driver planning', (tester) async {
    await pumpApp(tester, location: '/missions', missions: gateway());
    await tapText(tester, 'Planning');
    expect(find.byType(PlanningScreen), findsOneWidget);
  });

  testWidgets('renders the current week like the validated prototype', (tester) async {
    await pumpApp(tester, location: '/planning', missions: gateway());

    expect(find.text('Planning'), findsWidgets);
    expect(find.text('Novembre 2026'), findsOneWidget);
    expect(find.text('Semaine du 2 au 8 nov.'), findsOneWidget);
    for (final wd in ['LUN.', 'MAR.', 'MER.', 'JEU.', 'VEN.', 'SAM.', 'DIM.']) {
      expect(find.text(wd), findsWidgets);
    }
    expect(find.text("MARDI 3 NOVEMBRE · AUJOURD'HUI"), findsOneWidget);
    expect(find.text('À préparer'), findsOneWidget);
    expect(find.text('D-0139'), findsOneWidget);
    expect(find.text('Yamoussoukro'), findsOneWidget);
    expect(find.text('Mar. 3 nov. 07:30 → mer. 4 nov. 17:00'), findsOneWidget);
    expect(find.text('Land Cruiser · 1150 FB 01 · 2 passagers'), findsOneWidget);

    expect(find.text('RESTE DE LA SEMAINE'), findsOneWidget);
    expect(find.text('Abengourou'), findsOneWidget);
    expect(find.text('Korhogo'), findsNothing, reason: 'next week');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a day without mission shows the empty state', (tester) async {
    await pumpApp(tester, location: '/planning', missions: gateway());
    await tester.tap(find.bySemanticsLabel(RegExp('^Lundi 2 novembre')));
    await tester.pumpAndSettle();
    expect(find.text('LUNDI 2 NOVEMBRE'), findsOneWidget);
    expect(find.text('Aucune mission ce jour.'), findsOneWidget);
  });

  testWidgets('next week, then a row of « Reste de la semaine » selects its day', (tester) async {
    await pumpApp(tester, location: '/planning', missions: gateway());
    await tester.tap(find.bySemanticsLabel('Semaine suivante'));
    await tester.pumpAndSettle();

    expect(find.text('Semaine du 9 au 15 nov.'), findsOneWidget);
    expect(find.text('LUNDI 9 NOVEMBRE'), findsOneWidget);
    expect(find.text('Aucune mission ce jour.'), findsOneWidget);

    await tapText(tester, 'Korhogo');
    expect(find.text('MARDI 10 NOVEMBRE'), findsOneWidget);
    expect(find.text('Mar. 10 nov. 06:00 → ven. 13 nov. 17:00'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Semaine précédente'));
    await tester.pumpAndSettle();
    expect(find.text('Semaine du 2 au 8 nov.'), findsOneWidget);
  });

  testWidgets('a mission to prepare opens the departure preparation', (tester) async {
    await pumpApp(tester, location: '/planning', missions: gateway());
    await tapText(tester, 'Yamoussoukro');
    expect(find.byType(DeparturePreparationScreen), findsOneWidget);
  });

  testWidgets('before the departure day, a mission is « À venir » and the departure check stays closed', (tester) async {
    await pumpApp(tester, location: '/planning', missions: gateway());
    await tester.tap(find.bySemanticsLabel('Semaine suivante'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Korhogo');

    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('À préparer'), findsNothing);
    expect(find.text('Le contrôle de départ s’ouvre le jour du départ.'), findsOneWidget);
    await tapText(tester, 'Korhogo');
    expect(find.byType(DeparturePreparationScreen), findsNothing);
  });

  testWidgets('a mission under way is « En cours » and opens the mission in progress', (tester) async {
    final now = DateTime(2026, 11, 3, 9, 16);
    await pumpApp(tester, location: '/planning', now: now, missions: FakeMissionsGateway(rows: inProgressRows(now)));
    expect(find.text('En cours'), findsOneWidget);
    await tapText(tester, 'Bouaké');
    expect(find.byType(MissionInProgressScreen), findsOneWidget);
  });
}
