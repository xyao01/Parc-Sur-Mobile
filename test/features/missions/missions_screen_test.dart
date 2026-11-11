import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/presentation/departure_check_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the day mission and upcoming missions like the prototype', (tester) async {
    await pumpApp(tester, location: '/missions');

    expect(find.text('Bonjour, Yao'), findsOneWidget);
    expect(find.text('YK'), findsOneWidget);
    expect(find.text("Mardi 3 novembre · 1 mission aujourd'hui"), findsOneWidget);
    expect(find.text('MISSION DU JOUR'), findsOneWidget);
    expect(find.text('Départ à 07:30'), findsOneWidget);
    expect(find.text('D-0139'), findsOneWidget);
    expect(find.text('Abidjan'), findsOneWidget);
    expect(find.text('Yamoussoukro'), findsOneWidget);
    expect(find.text('Land Cruiser · 1150 FB 01'), findsOneWidget);
    expect(find.text('Mer. 4 nov. · 17:00'), findsOneWidget);
    expect(find.text('Koffi Ouattara'), findsOneWidget);

    expect(find.text('À VENIR'), findsOneWidget);
    expect(find.text('VEN.'), findsOneWidget);
    expect(find.text('Abengourou'), findsOneWidget);
    expect(find.text('Toyota Prado · 06:00 → sam. 18:00'), findsOneWidget);
    expect(find.text('MAR.'), findsOneWidget);
    expect(find.text('Véhicule à confirmer · 06:00 → ven. 17:00'), findsOneWidget);

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
}
