import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/features/auth/presentation/login_screen.dart';
import 'package:parc_sur_mobile/features/profile/presentation/profile_screen.dart';

import '../../helpers/fake_auth_gateway.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the signed-in user and roles', (tester) async {
    await pumpApp(tester, location: '/profil');

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('YK'), findsOneWidget);
    expect(find.text('Yao Kouadio'), findsOneWidget);
    expect(find.text('yao.kouadio@ministere.ci'), findsOneWidget);
    expect(find.text('Chauffeur'), findsOneWidget);
    expect(find.text('Demandeur'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Profil tab opens the profile page', (tester) async {
    await pumpApp(tester, location: '/missions');

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('"Se déconnecter" signs out on Supabase and returns to login', (tester) async {
    final gateway = FakeAuthGateway();
    await pumpApp(tester, location: '/profil', gateway: gateway);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(gateway.calls, contains('signOut'));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Protected pages are no longer reachable.
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
