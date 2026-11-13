import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/core/features.dart';
import 'package:parc_sur_mobile/core/widgets/maintenance_screen.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';
import 'package:parc_sur_mobile/features/auth/presentation/login_screen.dart';
import 'package:parc_sur_mobile/features/missions/presentation/chauffeur_nav.dart';
import 'package:parc_sur_mobile/features/profile/data/profile_gateway.dart';
import 'package:parc_sur_mobile/features/profile/presentation/change_password_screen.dart';
import 'package:parc_sur_mobile/features/profile/presentation/profile_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/demandeur_nav.dart';
import 'package:parc_sur_mobile/features/requests/presentation/requester_home_screen.dart';

import '../../helpers/fake_auth_gateway.dart';
import '../../helpers/fake_profile_gateway.dart';
import '../../helpers/pump_app.dart';

const requester = MobileProfile(
  firstName: 'Koffi',
  lastName: 'Ouattara',
  email: 'koffi.ouattara@ministere.ci',
  roles: {AppRole.demandeur},
);

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Profil tab opens the profile page', (tester) async {
    await pumpApp(tester, location: '/missions');
    await tapText(tester, 'Profil');
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('driver and requester: header, roles and « Mon espace »', (tester) async {
    await pumpApp(tester, location: '/profil');

    expect(find.text('YK'), findsOneWidget);
    expect(find.text('Yao Kouadio'), findsOneWidget);
    expect(find.text('yao.kouadio@ministere.ci'), findsOneWidget);
    expect(find.text('Chauffeur'), findsOneWidget);
    expect(find.text('Demandeur'), findsOneWidget);
    expect(find.text('MON ESPACE'), findsOneWidget);
    expect(find.text('Espace chauffeur'), findsOneWidget);
    expect(find.text('Espace demandeur'), findsOneWidget);
    expect(find.byType(ChauffeurBottomNav), findsOneWidget);
    expect(find.text('Changer mon mot de passe'), findsOneWidget);
    expect(find.text("Besoin d'aide ? Contactez l'administrateur de ParcSûr."), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to the requester space opens its home, without signing out', (tester) async {
    final auth = FakeAuthGateway();
    await pumpApp(tester, location: '/profil', gateway: auth);
    await tapText(tester, 'Espace demandeur');

    expect(find.byType(RequesterHomeScreen), findsOneWidget);
    expect(auth.calls, isNot(contains('signOut')));

    await tapText(tester, 'Profil');
    expect(find.byType(DemandeurBottomNav), findsOneWidget);
    expect(find.text('+225 07 00 00 00 00'), findsOneWidget);
  });

  testWidgets('driver: « Mes informations » from ma_fiche_chauffeur (Mob-P01)', (tester) async {
    await pumpApp(tester, location: '/profil');

    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('+225 05 11 22 33 44'), findsOneWidget);
    expect(find.text('Permis'), findsOneWidget);
    expect(find.text('B, C'), findsOneWidget);
    expect(find.text('Fin de validité'), findsOneWidget);
    expect(find.text('12/03/2027'), findsOneWidget);
    expect(find.text('Modifier mes coordonnées'), findsOneWidget);
    expect(find.text('Signaler une erreur à mon gestionnaire'), findsOneWidget);
  });

  testWidgets('driver: empty record shows dashes', (tester) async {
    await pumpApp(
      tester,
      location: '/profil',
      profiles: FakeProfileGateway(driverRecord: const {'telephone': null, 'permis': [], 'finValidite': null}),
    );
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('driver: load error, then retry', (tester) async {
    final profiles = FakeProfileGateway(driverError: const ProfileGatewayException('Connexion impossible.'));
    await pumpApp(tester, location: '/profil', profiles: profiles);
    expect(find.text('Impossible de charger vos informations.'), findsOneWidget);

    profiles.driverError = null;
    await tapText(tester, 'Réessayer');
    expect(find.text('B, C'), findsOneWidget);
  });

  testWidgets('driver: « Modifier mes coordonnées » saves name and phone, not the licence', (tester) async {
    final profiles = FakeProfileGateway();
    await pumpApp(tester, location: '/profil', profiles: profiles);
    await tapText(tester, 'Modifier mes coordonnées');

    expect(find.text('Mes coordonnées'), findsOneWidget);
    expect(find.byKey(const Key('account.location')), findsNothing);
    expect(find.text('Le permis est mis à jour par votre gestionnaire.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('account.phone')), '+225 01 99 88 77 66');
    await tester.enterText(find.byKey(const Key('account.lastName')), 'Kouadio-Brou');
    await tapText(tester, 'Enregistrer');

    expect(profiles.driverUpdates.single, {'prenom': 'Yao', 'nom': 'Kouadio-Brou', 'phone': '+225 01 99 88 77 66'});
    expect(profiles.updates, isEmpty);
    expect(find.text('Coordonnées enregistrées'), findsOneWidget);
    expect(find.text('Vos coordonnées ont été enregistrées.'), findsOneWidget);
    await tapText(tester, 'Fermer');
    expect(find.text('Mes coordonnées'), findsNothing);
    expect(find.text('Yao Kouadio-Brou'), findsOneWidget);
    expect(find.text('+225 01 99 88 77 66'), findsOneWidget);
  });

  testWidgets('driver: the server refusal is shown in the sheet', (tester) async {
    final profiles = FakeProfileGateway(updateError: const ProfileGatewayException('Saisissez votre nom.'));
    await pumpApp(tester, location: '/profil', profiles: profiles);
    await tapText(tester, 'Modifier mes coordonnées');
    await tapText(tester, 'Enregistrer');
    expect(find.text('Saisissez votre nom.'), findsOneWidget);
  });

  testWidgets('driver: « Signaler une erreur à mon gestionnaire » opens « Page en maintenance »', (tester) async {
    await pumpApp(tester, location: '/profil', features: const Features());
    await tapText(tester, 'Signaler une erreur à mon gestionnaire');
    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(find.text('Signaler une erreur'), findsOneWidget);
  });

  testWidgets('requester only: no space switch, details from Supabase', (tester) async {
    await pumpApp(tester, location: '/profil', profile: requester);

    expect(find.text('MON ESPACE'), findsNothing);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('+225 07 00 00 00 00'), findsOneWidget);
    expect(find.text('Fonction'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('Abidjan, Plateau'), findsOneWidget);
    expect(find.byType(DemandeurBottomNav), findsOneWidget);
  });

  testWidgets('« Modifier mes coordonnées » saves through modifier_mon_compte', (tester) async {
    final profiles = FakeProfileGateway();
    await pumpApp(tester, location: '/profil', profile: requester, profiles: profiles);
    await tapText(tester, 'Modifier mes coordonnées');

    expect(find.text('Mes coordonnées'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('account.phone')), '+225 01 02 03 04 05');
    await tester.enterText(find.byKey(const Key('account.firstName')), 'Koffi Jean');
    await tapText(tester, 'Enregistrer');

    expect(profiles.updates.single, {
      'prenom': 'Koffi Jean',
      'nom': 'Ouattara',
      'phone': '+225 01 02 03 04 05',
      'localisation': 'Abidjan, Plateau',
    });
    expect(find.text('Vos coordonnées ont été enregistrées.'), findsOneWidget);
    await tapText(tester, 'Fermer');
    expect(find.text('Mes coordonnées'), findsNothing);
    expect(find.text('Koffi Jean Ouattara'), findsOneWidget);
    expect(find.text('+225 01 02 03 04 05'), findsOneWidget);
  });

  testWidgets('the server refusal is shown in the sheet', (tester) async {
    final profiles = FakeProfileGateway(updateError: const ProfileGatewayException('Saisissez votre numéro de téléphone.'));
    await pumpApp(tester, location: '/profil', profile: requester, profiles: profiles);
    await tapText(tester, 'Modifier mes coordonnées');
    await tapText(tester, 'Enregistrer');
    expect(find.text('Saisissez votre numéro de téléphone.'), findsOneWidget);
  });

  testWidgets('« Changer mon mot de passe » saves the new password', (tester) async {
    final auth = FakeAuthGateway();
    await pumpApp(tester, location: '/profil', gateway: auth);
    await tapText(tester, 'Changer mon mot de passe');

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('newPassword.password')), matching: find.byType(EditableText)),
      'Parcsur2027',
    );
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('newPassword.confirmation')), matching: find.byType(EditableText)),
      'Parcsur2027',
    );
    await tapText(tester, 'Enregistrer le mot de passe');

    expect(auth.calls, contains('updatePassword:Parcsur2027'));
    expect(find.text('Votre mot de passe a été modifié.'), findsOneWidget);
  });

  testWidgets('« Se déconnecter » asks for confirmation, then signs out', (tester) async {
    final auth = FakeAuthGateway();
    await pumpApp(tester, location: '/profil', gateway: auth);

    await tapText(tester, 'Se déconnecter');
    expect(find.text('Se déconnecter ?'), findsOneWidget);
    await tapText(tester, 'Annuler');
    expect(auth.calls, isNot(contains('signOut')));

    await tapText(tester, 'Se déconnecter');
    await tapText(tester, 'Se déconnecter');
    expect(auth.calls, contains('signOut'));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
