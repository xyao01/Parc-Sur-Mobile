import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/connectivity.dart';
import 'package:parc_sur_mobile/features/missions/presentation/missions_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  const location = '/missions/D-0139/controle-depart';

  bool isSelected(WidgetTester tester, String label) {
    final node = tester.getSemantics(find.byKey(ValueKey('departure.option.$label')));
    return node.flagsCollection.isSelected == Tristate.isTrue || node.flagsCollection.isChecked == CheckedState.isTrue;
  }

  testWidgets('renders the prototype departure check', (tester) async {
    await pumpApp(tester, location: location);

    expect(find.text('Contrôle de départ'), findsOneWidget);
    expect(find.text('Land Cruiser · 1150 FB 01'), findsOneWidget);
    expect(find.text('Kilométrage au compteur'), findsOneWidget);
    expect(find.text('Cohérent avec le dernier relevé (84 112 km le 30/10)'), findsOneWidget);
    expect(find.text('Niveau de carburant'), findsOneWidget);
    for (final level in ['1/4', '1/2', '3/4', 'Plein']) {
      expect(find.text(level), findsOneWidget);
    }
    expect(find.text('État du véhicule'), findsOneWidget);
    expect(find.text('Pneus et roue de secours'), findsOneWidget);
    expect(find.text('Documents à bord'), findsOneWidget);
    expect(find.text('Valider le départ'), findsOneWidget);
    expect(find.bySemanticsLabel('Étape 2 sur 3'), findsOneWidget);
    // Online by default: no offline banner.
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
    expect(find.text('Cohérent avec le dernier relevé (84 112 km le 30/10)'), findsNothing);
    expect(find.text('Inférieur au dernier relevé (84 112 km le 30/10)'), findsOneWidget);
  });

  testWidgets('back button returns to missions', (tester) async {
    await pumpApp(tester, location: location);

    await tester.tap(find.bySemanticsLabel('Retour aux missions'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionsScreen), findsOneWidget);
  });
}
