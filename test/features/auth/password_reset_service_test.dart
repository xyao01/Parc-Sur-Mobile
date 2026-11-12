import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/auth_service.dart';
import 'package:parc_sur_mobile/features/auth/domain/login_failure.dart';

import '../../helpers/fake_auth_gateway.dart';

void main() {
  const redirect = 'com.syabetech.parcsur://reinitialiser-mot-de-passe';

  group('requestPasswordReset', () {
    test('sends the reset e-mail with the app redirect, e-mail normalised', () async {
      final gateway = FakeAuthGateway();
      await AuthService(gateway).requestPasswordReset('  Yao.Kouadio@Ministere.ci ', redirectTo: redirect);
      expect(gateway.calls, ['requestReset:yao.kouadio@ministere.ci>$redirect']);
    });

    test('asks for the e-mail when empty, without calling the server', () async {
      final gateway = FakeAuthGateway();
      await expectLater(
        AuthService(gateway).requestPasswordReset('  ', redirectTo: redirect),
        throwsA(isA<MissingEmail>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('reports the send limit (HTTP 429), as the web app', () async {
      final gateway = FakeAuthGateway(resetError: AuthGatewayError.rateLimited);
      await expectLater(
        AuthService(gateway).requestPasswordReset('a@b.ci', redirectTo: redirect),
        throwsA(isA<TooManyResetRequests>()),
      );
    });

    test('reports a network failure', () async {
      final gateway = FakeAuthGateway(resetError: AuthGatewayError.network);
      await expectLater(
        AuthService(gateway).requestPasswordReset('a@b.ci', redirectTo: redirect),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('any other server answer looks like a success (does not reveal unknown accounts)', () async {
      final gateway = FakeAuthGateway(resetError: AuthGatewayError.other);
      await AuthService(gateway).requestPasswordReset('inconnu@b.ci', redirectTo: redirect);
    });
  });

  group('resetPassword', () {
    test('saves the new password then closes the recovery session (web order)', () async {
      final gateway = FakeAuthGateway();
      await AuthService(gateway).resetPassword('Parcsur2026', 'Parcsur2026');
      expect(gateway.calls, ['updatePassword:Parcsur2026', 'signOut']);
    });

    test('applies the password policy before calling the server', () async {
      final gateway = FakeAuthGateway();
      await expectLater(AuthService(gateway).resetPassword('abc', 'abc'), throwsA(isA<PasswordPolicyFailure>()));
      expect(gateway.calls, isEmpty);
    });

    test('refuses two different passwords', () async {
      final gateway = FakeAuthGateway();
      await expectLater(
        AuthService(gateway).resetPassword('Parcsur2026', 'Parcsur2027'),
        throwsA(isA<PasswordMismatch>()),
      );
    });

    test('maps the server refusing the current password', () async {
      final gateway = FakeAuthGateway(updatePasswordError: AuthGatewayError.samePassword);
      await expectLater(AuthService(gateway).resetPassword('Parcsur2026', 'Parcsur2026'), throwsA(isA<SamePassword>()));
      expect(gateway.calls, isNot(contains('signOut')));
    });
  });
}
