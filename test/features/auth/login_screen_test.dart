import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/missions/presentation/missions_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/new_request_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the prototype login screen', (tester) async {
    await pumpApp(tester, location: '/connexion');

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('La gestion du parc, en toute sérénité.'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text("Utiliser l'empreinte digitale"), findsOneWidget);
    expect(find.text("Besoin d'aide ? Contactez l'administrateur de ParcSûr."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles password visibility', (tester) async {
    await pumpApp(tester, location: '/connexion');

    EditableText password() => tester.widget<EditableText>(
          find.descendant(of: find.byKey(const Key('login.password')), matching: find.byType(EditableText)),
        );

    expect(password().obscureText, isTrue);
    await tester.tap(find.bySemanticsLabel('Afficher le mot de passe'));
    await tester.pump();
    expect(password().obscureText, isFalse);
    expect(find.bySemanticsLabel('Masquer le mot de passe'), findsOneWidget);
  });

  testWidgets('"Se connecter" opens the chauffeur home by default', (tester) async {
    await pumpApp(tester, location: '/connexion');

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionsScreen), findsOneWidget);
  });

  testWidgets('"Se connecter" opens the demandeur home when that role is configured', (tester) async {
    await pumpApp(
      tester,
      location: '/connexion',
      overrides: [currentRoleProvider.overrideWithValue(AppRole.demandeur)],
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.byType(NewRequestScreen), findsOneWidget);
  });
}
