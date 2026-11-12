import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/auth_service.dart';

import '../../helpers/fake_auth_gateway.dart';

void main() {
  group('restore (session kept by Supabase across launches)', () {
    test('no stored session: signed out, nothing called', () async {
      final gateway = FakeAuthGateway();
      expect(await AuthService(gateway).restore(), isNull);
      expect(gateway.calls, ['currentAccount']);
    });

    test('stored session: reloads the mobile profile, without counting a new sign-in', () async {
      final gateway = FakeAuthGateway()..storedAccount = const SignInResult(email: 'a@b.ci', provisionalPassword: false);
      final profile = await AuthService(gateway).restore();

      expect(profile?.firstName, 'Yao');
      expect(profile?.roles, {AppRole.chauffeur});
      expect(profile?.email, 'a@b.ci');
      expect(gateway.calls, ['currentAccount', 'mobileProfile']);
    });

    test('keeps the provisional password flag', () async {
      final gateway = FakeAuthGateway()..storedAccount = const SignInResult(email: 'a@b.ci', provisionalPassword: true);
      expect((await AuthService(gateway).restore())?.mustChangePassword, isTrue);
    });

    test('account without mobile role any more: signed out', () async {
      final gateway = FakeAuthGateway(profile: {'prenom': 'A', 'nom': 'B', 'demandeur': false, 'chauffeur': false})
        ..storedAccount = const SignInResult(email: 'a@b.ci', provisionalPassword: false);
      expect(await AuthService(gateway).restore(), isNull);
      expect(gateway.calls.last, 'signOut');
    });

    test('server unreachable: back to sign-in, session kept for the next launch', () async {
      final gateway = FakeAuthGateway(profileError: AuthGatewayError.network)
        ..storedAccount = const SignInResult(email: 'a@b.ci', provisionalPassword: false);
      expect(await AuthService(gateway).restore(), isNull);
      expect(gateway.calls, isNot(contains('signOut')));
    });
  });
}
