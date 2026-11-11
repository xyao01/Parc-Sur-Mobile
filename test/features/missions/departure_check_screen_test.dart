import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/connectivity.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/presentation/missions_screen.dart';

import '../../helpers/fake_missions_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  const location = '/missions/m-139/controle-depart';

  bool isSelected(WidgetTester tester, String label) {
    final node = tester.getSemantics(find.byKey(ValueKey('departure.option.$label')));
    return node.flagsCollection.isSelected == Tristate.isTrue || node.flagsCollection.isChecked == CheckedState.isTrue;
  }

  testWidgets('renders the prototype departure check', (tester) async {
    await pumpApp(tester, location: location);

    expect(find.text('Contrôle de départ'), findsOneWidget);
    expect(find.text('Land Cruiser · 1150 FB 01'), findsOneWidget);
    expect(find.text('Kilométrage au compteur'), findsOneWidget);
    expect(find.text('Cohérent avec le dernier relevé (84 112 km)'), findsOneWidget);
    expect(find.text('Niveau de carburant'), findsOneWidget);
    for (final level in ['1/4', '1/2', '3/4', 'Plein']) {
      expect(find.text(level), findsOneWidget);
    }
    expect(find.text('État du véhicule'), findsOneWidget);
    expect(find.text('Pneus et roue de secours'), findsOneWidget);
    expect(find.text('Documents à bord'), findsOneWidget);
    expect(find.text('Valider le départ'), findsOneWidget);
    expect(find.bySemanticsLabel('Étape 2 sur 3'), findsOneWidget);
    expect(find.textContaining('Hors connexion'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the offline banner when the device is offline', (tester) async {
    await pumpApp(tester, location: location, overrides: [isOfflineProvider.overrideWithValue(true)]);

    expect(find.text('Hors connexion : la saisie sera envoyée dès le retour du réseau.'), findsOneWidget);
  });

  testWidgets('selects one fuel level at a time', (tester) async {
    await pumpApp(tester, location: location);

    await tester.tap(find.text('Plein'));
    await tester.pump();
    expect(isSelected(tester, 'Plein'), isTrue);
    expect(isSelected(tester, '3/4'), isFalse);
  });

  testWidgets('toggles a vehicle check item', (tester) async {
    await pumpApp(tester, location: location);

    expect(isSelected(tester, 'Feux et clignotants'), isFalse);
    await tester.tap(find.text('Feux et clignotants'));
    await tester.pump();
    expect(isSelected(tester, 'Feux et clignotants'), isTrue);
  });

  testWidgets('flags a reading lower than the last one', (tester) async {
    await pumpApp(tester, location: location);

    await tester.enterText(find.byKey(const Key('departure.odometer')), '84000');
    await tester.pump();
    expect(find.text('Inférieur au dernier relevé (84 112 km)'), findsOneWidget);
  });

  testWidgets('"Valider le départ" records the check on Supabase and returns to missions', (tester) async {
    final gateway = FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow));
    await pumpApp(tester, location: '/missions', missions: gateway);
    await tester.tap(find.text('Commencer le contrôle de départ'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('departure.odometer')), '84 230');
    await tester.tap(find.text('Pneus et roue de secours'));
    await tester.tap(find.text('Feux et clignotants'));
    await tester.tap(find.text('Documents à bord'));
    await tester.tap(find.text('Valider le départ'));
    await tester.pumpAndSettle();

    expect(gateway.recorded, hasLength(1));
    final r = gateway.recorded.single;
    expect(r['missionId'], 'm-139');
    expect(r['type'], 'depart');
    expect(r['km'], 84230);
    expect(r['fuel'], 'trois_quarts');
    expect(r['points'], {'pneus': 'ok', 'eclairage': 'ok', 'carrosserie': 'anomalie', 'documents': 'ok'});
    expect((r['id'] as String).length, 36);

    expect(find.byType(MissionsScreen), findsOneWidget);
    expect(find.text('Commencer le contrôle de départ'), findsNothing);
  });

  testWidgets('requires the odometer reading', (tester) async {
    final gateway = FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow));
    await pumpApp(tester, location: location, missions: gateway);

    await tester.tap(find.text('Valider le départ'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez le kilométrage au compteur.'), findsOneWidget);
    expect(gateway.recorded, isEmpty);
  });

  testWidgets('shows the server refusal', (tester) async {
    final gateway = FakeMissionsGateway(
      rows: prototypeMissionRows(prototypeNow),
      recordError: const MissionsGatewayException('Cette mission ne vous est pas attribuée.'),
    );
    await pumpApp(tester, location: location, missions: gateway);

    await tester.enterText(find.byKey(const Key('departure.odometer')), '84230');
    await tester.tap(find.text('Valider le départ'));
    await tester.pumpAndSettle();
    expect(find.text('Cette mission ne vous est pas attribuée.'), findsOneWidget);
  });

  testWidgets('back button returns to missions', (tester) async {
    await pumpApp(tester, location: location);

    await tester.tap(find.bySemanticsLabel('Retour aux missions'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionsScreen), findsOneWidget);
  });
}
