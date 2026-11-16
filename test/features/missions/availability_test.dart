import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

const onText = 'Les nouvelles demandes peuvent vous être confiées';
const offText = 'Vous ne recevrez pas de nouvelles demandes';

Finder get toggle => find.bySemanticsLabel('Disponibilité');

Future<void> tapToggle(WidgetTester tester) async {
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

void main() {
  group('Mob-C01 · « Je suis disponible » (absence du chauffeur)', () {
    testWidgets('switching off declares the driver unavailable at the time of the tap', (tester) async {
      final g = FakeMissionsGateway(rows: const []);
      await pumpApp(tester, location: '/missions', missions: g);
      expect(find.text(onText), findsOneWidget);

      await tapToggle(tester);

      expect(g.availabilityCalls.single, containsPair('available', false));
      expect(g.availabilityCalls.single['at'], prototypeNow);
      expect(g.availabilityCalls.single['id'], isA<String>());
      expect(find.text(offText), findsOneWidget);
    });

    testWidgets('switching back on ends the absence at the time of the tap', (tester) async {
      final g = FakeMissionsGateway(rows: const [])..available = false;
      await pumpApp(tester, location: '/missions', missions: g);
      expect(find.text(offText), findsOneWidget);

      await tapToggle(tester);

      expect(g.availabilityCalls.single, {'available': true, 'at': prototypeNow});
      expect(find.text(onText), findsOneWidget);
    });

    testWidgets('a mission assigned today: refused with the server message, still available', (tester) async {
      final g = FakeMissionsGateway(rows: const [])
        ..availabilityError =
            const MissionsGatewayException('Une mission vous est attribuée aujourd’hui : prévenez votre gestionnaire.');
      await pumpApp(tester, location: '/missions', missions: g);

      await tapToggle(tester);

      expect(find.text('Une mission vous est attribuée aujourd’hui : prévenez votre gestionnaire.'), findsOneWidget);
      expect(find.text(onText), findsOneWidget);
    });
  });
}
