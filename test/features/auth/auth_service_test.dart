import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/auth_service.dart';
import 'package:parc_sur_mobile/features/auth/domain/login_failure.dart';

import '../../helpers/fake_auth_gateway.dart';

void main() {
  final until = DateTime(2026, 11, 11, 10, 19);

  test('normalises the email, signs in, records success and returns the mobile profile', () async {
    final gateway = FakeAuthGateway();
    final profile = await AuthService(gateway).signIn('  Yao.Kouadio@Ministere.ci ', 'secret');

    expect(gateway.calls, [
      'lockedUntil:yao.kouadio@ministere.ci',
      'signIn:yao.kouadio@ministere.ci',
      'recordSuccess',
      'mobileProfile',
    ]);
    expect(profile.firstName, 'Yao');
    expect(profile.lastName, 'Kouadio');
    expect(profile.roles, {AppRole.chauffeur});
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

  test('signs out and refuses an account without any mobile role', () async {
    final gateway = FakeAuthGateway(profile: {'prenom': 'Awa', 'nom': 'Diallo', 'demandeur': false, 'chauffeur': false});

    await expectLater(AuthService(gateway).signIn('a@b.ci', 'x'), throwsA(isA<NoMobileAccess>()));
    expect(gateway.calls.last, 'signOut');
  });

  test('rejects empty fields without calling the server', () async {
    final gateway = FakeAuthGateway();

    await expectLater(AuthService(gateway).signIn(' ', ''), throwsA(isA<MissingFields>()));
    expect(gateway.calls, isEmpty);
  });

  test('home route prefers the configured role when the user has both', () {
    expect(homeRouteFor({AppRole.chauffeur, AppRole.demandeur}), '/missions');
    expect(homeRouteFor({AppRole.demandeur}), '/demandes/nouvelle');
    expect(homeRouteFor({AppRole.chauffeur}), '/missions');
  });
}
