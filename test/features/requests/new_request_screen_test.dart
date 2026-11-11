import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  const location = '/demandes/nouvelle';

  testWidgets('renders the prototype new request form', (tester) async {
    await pumpApp(tester, location: location);

    expect(find.text('Nouvelle demande'), findsOneWidget);
    expect(find.text('Véhicule de mission'), findsOneWidget);
    expect(find.text('Motif de la mission'), findsOneWidget);
    expect(find.text('Destination(s)'), findsOneWidget);
    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Passagers'), findsOneWidget);
    expect(find.text("Besoin d'un chauffeur"), findsOneWidget);
    expect(find.text('Précisions (facultatif)'), findsOneWidget);
    expect(
      find.text('Votre demande sera examinée par un administrateur. Vous recevrez une notification dès sa validation.'),
      findsOneWidget,
    );
    expect(find.text('Envoyer la demande'), findsOneWidget);
    for (final tab in ['Accueil', 'Mes demandes', 'Alertes', 'Profil']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('passenger stepper increments and never goes below the minimum', (tester) async {
    await pumpApp(tester, location: location);

    final count = find.byKey(const Key('request.passengers'));
    expect(tester.widget<Text>(count).data, '1');

    await tester.tap(find.bySemanticsLabel('Ajouter un passager'));
    await tester.tap(find.bySemanticsLabel('Ajouter un passager'));
    await tester.pump();
    expect(tester.widget<Text>(count).data, '3');

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.bySemanticsLabel('Retirer un passager'));
    }
    await tester.pump();
    expect(tester.widget<Text>(count).data, '1');
  });

  testWidgets('driver switch toggles', (tester) async {
    await pumpApp(tester, location: location);

    final toggle = find.byKey(const Key('request.needDriver'));
    expect(tester.getSemantics(toggle).flagsCollection.isToggled.toBoolOrNull(), isTrue);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.getSemantics(toggle).flagsCollection.isToggled.toBoolOrNull(), isFalse);
  });
}
