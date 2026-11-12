import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/presentation/login_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/driver_home_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/new_request_screen.dart';

import '../../helpers/fake_auth_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('login.email')), 'yao.kouadio@ministere.ci');
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('login.password')), matching: find.byType(EditableText)),
      'secret',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the prototype login screen', (tester) async {
    await pumpApp(tester, location: '/connexion', signedIn: false);

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
    await pumpApp(tester, location: '/connexion', signedIn: false);

    EditableText password() => tester.widget<EditableText>(
          find.descendant(of: find.byKey(const Key('login.password')), matching: find.byType(EditableText)),
        );

    expect(password().obscureText, isTrue);
    await tester.tap(find.bySemanticsLabel('Afficher le mot de passe'));
    await tester.pump();
    expect(password().obscureText, isFalse);
    expect(find.bySemanticsLabel('Masquer le mot de passe'), findsOneWidget);
  });

  testWidgets('a chauffeur lands on missions, greeted by name', (tester) async {
    final gateway = FakeAuthGateway(profile: {'prenom': 'Koné', 'nom': 'Ibrahim', 'demandeur': false, 'chauffeur': true});
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

    await fillAndSubmit(tester);
    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.text('Bonjour, Koné'), findsOneWidget);
    expect(find.text('KI'), findsOneWidget);
  });

  testWidgets('a demandeur lands on the new request form', (tester) async {
    final gateway = FakeAuthGateway(profile: {'prenom': 'Awa', 'nom': 'Diallo', 'demandeur': true, 'chauffeur': false});
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

    await fillAndSubmit(tester);
    expect(find.byType(NewRequestScreen), findsOneWidget);
  });

  testWidgets('shows the web prototype message when the account gets locked', (tester) async {
    final gateway = FakeAuthGateway(
      signInError: AuthGatewayError.invalidCredentials,
      lockAfterFailure: DateTime(2026, 11, 11, 10, 19),
    );
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

    await fillAndSubmit(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Compte bloqué après 5 tentatives échouées. Réessayez à partir de 10:19.'), findsOneWidget);
  });

  testWidgets('shows an error on wrong credentials', (tester) async {
    final gateway = FakeAuthGateway(signInError: AuthGatewayError.invalidCredentials);
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

    await fillAndSubmit(tester);
    expect(find.text('Adresse e-mail ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('refuses an account without mobile access', (tester) async {
    final gateway = FakeAuthGateway(profile: {'prenom': 'A', 'nom': 'B', 'demandeur': false, 'chauffeur': false});
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

    await fillAndSubmit(tester);
    expect(
      find.text("Ce compte n'a pas accès à l'application mobile. Contactez l'administrateur de ParcSûr."),
      findsOneWidget,
    );
  });

  testWidgets('signed-out users are sent back to the login screen', (tester) async {
    await pumpApp(tester, location: '/missions', signedIn: false);

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
