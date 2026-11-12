import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/auth_service.dart';
import 'package:parc_sur_mobile/features/auth/domain/login_failure.dart';
import 'package:parc_sur_mobile/features/auth/domain/password_policy.dart';

import '../../helpers/fake_auth_gateway.dart';

void main() {
  final until = DateTime(2026, 11, 11, 10, 19);

  group('signIn', () {
    test('checks lock, signs in, reads the profile, then records success (web order)', () async {
      final gateway = FakeAuthGateway();
      final profile = await AuthService(gateway).signIn('  Yao.Kouadio@Ministere.ci ', 'secret');

      expect(gateway.calls, [
        'lockedUntil:yao.kouadio@ministere.ci',
        'signIn:yao.kouadio@ministere.ci',
        'mobileProfile',
        'recordSuccess',
      ]);
      expect(profile.firstName, 'Yao');
      expect(profile.lastName, 'Kouadio');
      expect(profile.email, 'yao.kouadio@ministere.ci');
      expect(profile.roles, {AppRole.chauffeur});
      expect(profile.mustChangePassword, isFalse);
    });

    test('logs the session for a demandeur (web audit journal)', () async {
      final gateway = FakeAuthGateway(profile: {'prenom': 'A', 'nom': 'D', 'demandeur': true, 'chauffeur': false});
      await AuthService(gateway).signIn('a@b.ci', 'x');
      expect(gateway.calls.last, 'logSession:connexion');
    });

    test('flags a provisional password', () async {
      final gateway = FakeAuthGateway(provisionalPassword: true);
      final profile = await AuthService(gateway).signIn('a@b.ci', 'x');
      expect(profile.mustChangePassword, isTrue);
    });

    test('refuses before calling auth when the account is already locked', () async {
      final gateway = FakeAuthGateway(lockedUntilValue: until);

      await expectLater(
        AuthService(gateway).signIn('a@b.ci', 'x'),
        throwsA(isA<AccountLocked>().having((f) => f.until, 'until', until)),
      );
      expect(gateway.calls, ['lockedUntil:a@b.ci']);
    });

    test('records a failure on wrong credentials', () async {
      final gateway = FakeAuthGateway(signInError: AuthGatewayError.invalidCredentials);

      await expectLater(AuthService(gateway).signIn('a@b.ci', 'x'), throwsA(isA<InvalidCredentials>()));
      expect(gateway.calls.last, 'recordFailure:a@b.ci');
    });

    test('reports the lock when the failure triggers it', () async {
      final gateway = FakeAuthGateway(signInError: AuthGatewayError.invalidCredentials, lockAfterFailure: until);

      await expectLater(
        AuthService(gateway).signIn('a@b.ci', 'x'),
        throwsA(isA<AccountLocked>().having((f) => f.until, 'until', until)),
      );
    });

    test('does not count a network error as a failed attempt', () async {
      final gateway = FakeAuthGateway(signInError: AuthGatewayError.network);

      await expectLater(AuthService(gateway).signIn('a@b.ci', 'x'), throwsA(isA<NetworkFailure>()));
      expect(gateway.calls, isNot(contains('recordFailure:a@b.ci')));
    });

    test('maps an unconfirmed email', () async {
      final gateway = FakeAuthGateway(signInError: AuthGatewayError.emailNotConfirmed);

      await expectLater(AuthService(gateway).signIn('a@b.ci', 'x'), throwsA(isA<EmailNotConfirmed>()));
    });

    test('signs out an account without mobile role, without calling connexion_reussie', () async {
      final gateway = FakeAuthGateway(profile: {'prenom': 'Awa', 'nom': 'Diallo', 'demandeur': false, 'chauffeur': false});

      await expectLater(AuthService(gateway).signIn('a@b.ci', 'x'), throwsA(isA<NoMobileAccess>()));
      expect(gateway.calls.last, 'signOut');
      expect(gateway.calls, isNot(contains('recordSuccess')));
    });

    test('rejects empty fields without calling the server', () async {
      final gateway = FakeAuthGateway();

      await expectLater(AuthService(gateway).signIn(' ', ''), throwsA(isA<MissingFields>()));
      expect(gateway.calls, isEmpty);
    });
  });

  group('setPassword', () {
    test('rejects a password that breaks the policy without calling the server', () async {
      final gateway = FakeAuthGateway();
      await expectLater(AuthService(gateway).setPassword('abc', 'abc'), throwsA(isA<PasswordPolicyFailure>()));
      expect(gateway.calls, isEmpty);
    });

    test('rejects a confirmation that differs', () async {
      final gateway = FakeAuthGateway();
      await expectLater(AuthService(gateway).setPassword('Parcsur2026', 'Parcsur2027'), throwsA(isA<PasswordMismatch>()));
      expect(gateway.calls, isEmpty);
    });

    test('saves a valid password', () async {
      final gateway = FakeAuthGateway();
      await AuthService(gateway).setPassword('Parcsur2026', 'Parcsur2026');
      expect(gateway.calls, ['updatePassword:Parcsur2026']);
    });

    test('maps "same password" from the server', () async {
      final gateway = FakeAuthGateway(updatePasswordError: AuthGatewayError.samePassword);
      await expectLater(
        AuthService(gateway).setPassword('Parcsur2026', 'Parcsur2026'),
        throwsA(isA<SamePassword>()),
      );
    });
  });

  test('password criteria follow the web policy (8 chars, uppercase, digit)', () {
    expect(PasswordPolicy.criteria('parcsur2').map((c) => (c.label, c.ok)).toList(), [
      ('8 caractères minimum', true),
      ('Une majuscule', false),
      ('Un chiffre', true),
    ]);
    expect(PasswordPolicy.isValid('Parcsur2'), isTrue);
  });

  test('home route prefers the configured role when the user has both', () {
    expect(homeRouteFor({AppRole.chauffeur, AppRole.demandeur}), '/missions');
    expect(homeRouteFor({AppRole.demandeur}), '/demandes');
    expect(homeRouteFor({AppRole.chauffeur}), '/missions');
  });
}
