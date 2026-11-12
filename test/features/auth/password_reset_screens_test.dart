import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:parc_sur_mobile/features/auth/presentation/login_screen.dart';
import 'package:parc_sur_mobile/features/auth/presentation/reset_password_screen.dart';

import '../../helpers/fake_auth_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> fillPasswords(WidgetTester tester, String password, String confirmation) async {
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

  group('Mot de passe oublié', () {
    testWidgets('« Mot de passe oublié ? » opens the request page', (tester) async {
      await pumpApp(tester, location: '/connexion', signedIn: false);
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.text('Recevoir le lien'), findsOneWidget);
    });

    testWidgets('sends the reset e-mail through Supabase and confirms', (tester) async {
      final gateway = FakeAuthGateway();
      await pumpApp(tester, location: '/mot-de-passe-oublie', signedIn: false, gateway: gateway);

      await tester.enterText(find.byKey(const Key('forgot.email')), 'yao.kouadio@ministere.ci');
      await tester.tap(find.text('Recevoir le lien'));
      await tester.pumpAndSettle();

      expect(gateway.calls.single, startsWith('requestReset:yao.kouadio@ministere.ci>'));
      expect(find.textContaining('Si un compte existe pour yao.kouadio@ministere.ci'), findsOneWidget);
    });

    testWidgets('shows the send-limit message', (tester) async {
      await pumpApp(
        tester,
        location: '/mot-de-passe-oublie',
        signedIn: false,
        gateway: FakeAuthGateway(resetError: AuthGatewayError.rateLimited),
      );
      await tester.enterText(find.byKey(const Key('forgot.email')), 'a@b.ci');
      await tester.tap(find.text('Recevoir le lien'));
      await tester.pumpAndSettle();
      expect(find.text('Trop de demandes en peu de temps. Réessayez dans quelques minutes.'), findsOneWidget);
    });

    testWidgets('« Retour à la connexion » goes back to sign-in', (tester) async {
      await pumpApp(tester, location: '/mot-de-passe-oublie', signedIn: false);
      await tester.tap(find.text('Retour à la connexion'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Réinitialisation (lien reçu par e-mail)', () {
    testWidgets('opening the e-mail link shows the new password form', (tester) async {
      final gateway = FakeAuthGateway();
      await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);

      gateway.emitRecovery(RecoveryLink.opened);
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('Choisissez votre nouveau mot de passe.'), findsOneWidget);
      expect(find.text('Enregistrer le mot de passe'), findsOneWidget);
    });

    testWidgets('saves the password, closes the session and invites to sign in', (tester) async {
      final gateway = FakeAuthGateway();
      await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);
      gateway.emitRecovery(RecoveryLink.opened);
      await tester.pumpAndSettle();

      await fillPasswords(tester, 'Parcsur2026', 'Parcsur2026');
      await tester.tap(find.text('Enregistrer le mot de passe'));
      await tester.pumpAndSettle();

      expect(gateway.calls, ['updatePassword:Parcsur2026', 'signOut']);
      expect(find.text('Mot de passe enregistré'), findsOneWidget);

      await tester.tap(find.text('Aller à la connexion'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('an expired or used link offers a new one', (tester) async {
      final gateway = FakeAuthGateway();
      await pumpApp(tester, location: '/connexion', signedIn: false, gateway: gateway);
      gateway.emitRecovery(RecoveryLink.invalid);
      await tester.pumpAndSettle();

      expect(find.text('Lien expiré'), findsOneWidget);
      await tester.tap(find.text('Demander un nouveau lien'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('the page opened without a link is treated as expired', (tester) async {
      await pumpApp(tester, location: '/reinitialiser-mot-de-passe', signedIn: false);
      expect(find.text('Lien expiré'), findsOneWidget);
    });
  });
}
