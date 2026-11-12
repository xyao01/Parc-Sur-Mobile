import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/presentation/new_password_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/driver_home_screen.dart';

import '../../helpers/fake_auth_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> signInWithProvisional(WidgetTester tester, FakeAuthGateway gateway) async {
    await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);
    await tester.enterText(find.byKey(const Key('login.email')), 'yao.kouadio@ministere.ci');
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('login.password')), matching: find.byType(EditableText)),
      'Defaut2026',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String password, String confirmation) async {
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('newPassword.password')), matching: find.byType(EditableText)),
      password,
    );
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('newPassword.confirmation')), matching: find.byType(EditableText)),
      confirmation,
    );
    await tester.pump();
  }

  testWidgets('first sign-in with a provisional password opens the new password page', (tester) async {
    await signInWithProvisional(tester, FakeAuthGateway(provisionalPassword: true));

    expect(find.byType(NewPasswordScreen), findsOneWidget);
    expect(find.text('Nouveau mot de passe'), findsWidgets);
    expect(find.text('Choisissez votre nouveau mot de passe.'), findsOneWidget);
    expect(find.text('8 caractères minimum'), findsOneWidget);
    expect(find.text('Une majuscule'), findsOneWidget);
    expect(find.text('Un chiffre'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Enregistrer le mot de passe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cannot leave the page for another screen before choosing a password', (tester) async {
    await pumpApp(
      tester,
      location: '/missions',
      profile: prototypeProfile.copyWith(mustChangePassword: true),
    );
    expect(find.byType(NewPasswordScreen), findsOneWidget);
  });

  testWidgets('shows the policy message for a weak password', (tester) async {
    final gateway = FakeAuthGateway(provisionalPassword: true);
    await signInWithProvisional(tester, gateway);

    await fill(tester, 'abc', 'abc');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères, dont une majuscule et un chiffre.'),
      findsOneWidget,
    );
    expect(gateway.calls.where((c) => c.startsWith('updatePassword')), isEmpty);
  });

  testWidgets('shows a mismatch message', (tester) async {
    await signInWithProvisional(tester, FakeAuthGateway(provisionalPassword: true));

    await fill(tester, 'Parcsur2026', 'Parcsur2027');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Les deux mots de passe ne sont pas identiques.'), findsOneWidget);
  });

  testWidgets('saves the password on Supabase then opens the home screen', (tester) async {
    final gateway = FakeAuthGateway(provisionalPassword: true);
    await signInWithProvisional(tester, gateway);

    await fill(tester, 'Parcsur2026', 'Parcsur2026');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(gateway.calls, contains('updatePassword:Parcsur2026'));
    expect(find.byType(DriverHomeScreen), findsOneWidget);
  });

  testWidgets('reports the server refusing the default password', (tester) async {
    final gateway = FakeAuthGateway(provisionalPassword: true, updatePasswordError: AuthGatewayError.samePassword);
    await signInWithProvisional(tester, gateway);

    await fill(tester, 'Defaut2026', 'Defaut2026');
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez un mot de passe différent de l’actuel.'), findsOneWidget);
    expect(find.byType(NewPasswordScreen), findsOneWidget);
  });
}
