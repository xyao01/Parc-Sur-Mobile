import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/features/alerts/data/alerts_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';
import 'package:parc_sur_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:parc_sur_mobile/features/requests/presentation/demandeur_nav.dart';

import '../../helpers/fake_alerts_gateway.dart';
import '../../helpers/pump_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}


void main() {
  const driver = MobileProfile(firstName: 'Yao', lastName: 'Kouadio', roles: {AppRole.chauffeur});
  const requester = MobileProfile(firstName: 'Yao', lastName: 'Kouadio', roles: {AppRole.demandeur});

  FakeAlertsGateway gateway() => FakeAlertsGateway(driver: prototypeDriverAlerts(prototypeNow));

  testWidgets('the Alertes tab opens the alerts', (tester) async {
    await pumpApp(tester, location: '/missions', profile: driver, alerts: gateway());
    await tapText(tester, 'Alertes');
    expect(find.byType(AlertsScreen), findsOneWidget);
  });

  testWidgets('renders the driver alerts from Supabase like the validated prototype', (tester) async {
    final alerts = gateway();
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: alerts);

    expect(alerts.driverFetches, 1);
    expect(alerts.requesterFetches, 0, reason: 'driver only');
    expect(find.text('3 non lues'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsOneWidget);
    expect(find.text('Toutes'), findsOneWidget);
    expect(find.text('Non lues (3)'), findsOneWidget);
    expect(find.text("AUJOURD'HUI"), findsOneWidget);
    expect(find.text('HIER'), findsOneWidget);
    expect(find.text('PLUS ANCIENNES'), findsOneWidget);
    expect(find.text('Rappel : mission D-0142 demain'), findsOneWidget);
    expect(find.text('05:30'), findsOneWidget);
    expect(find.text('Échéance à J-30'), findsOneWidget);
    expect(find.text('17:40'), findsOneWidget);
    expect(find.text('Mission D-0131 attribuée'), findsOneWidget);
    expect(find.text('30 oct.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening an unread alert marks it read on the server', (tester) async {
    final alerts = gateway();
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: alerts);
    await tapText(tester, 'Rappel : mission D-0142 demain');

    expect(alerts.markedDriver, [
      ['a-1'],
    ]);
    expect(find.text('2 non lues'), findsOneWidget);
  });

  testWidgets('« Tout marquer comme lu » marks every alert read', (tester) async {
    final alerts = gateway();
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: alerts);
    await tapText(tester, 'Tout marquer comme lu');

    expect(alerts.markedDriver, [null]);
    expect(find.text('Tout est lu'), findsOneWidget);
    expect(find.text('Non lues (0)'), findsOneWidget);
  });

  testWidgets('« Non lues » hides the alerts already read', (tester) async {
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: gateway());
    await tapText(tester, 'Non lues (3)');
    expect(find.text('Mission D-0131 attribuée'), findsNothing);
    expect(find.text('Rappel : mission D-0142 demain'), findsOneWidget);
  });

  testWidgets('no alert: empty state', (tester) async {
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: FakeAlertsGateway());
    expect(find.text('Aucune alerte pour le moment'), findsOneWidget);
    expect(find.text('Tout est lu'), findsOneWidget);
  });

  testWidgets('a requester reads the alerts of their web account, with the requester tab bar', (tester) async {
    final alerts = FakeAlertsGateway(requester: prototypeDriverAlerts(prototypeNow).take(1).toList());
    await pumpApp(tester, location: '/alertes', profile: requester, alerts: alerts);

    expect(alerts.requesterFetches, 1);
    expect(alerts.driverFetches, 0);
    expect(find.byType(DemandeurBottomNav), findsOneWidget);
    await tapText(tester, 'Tout marquer comme lu');
    expect(alerts.markedRequester, [null]);
  });

  testWidgets('loading failure: message and retry', (tester) async {
    final alerts = FakeAlertsGateway(error: const AlertsGatewayException('boom'));
    await pumpApp(tester, location: '/alertes', profile: driver, alerts: alerts);
    expect(find.text('Impossible de charger vos alertes.'), findsOneWidget);

    alerts.error = null;
    alerts.driver = prototypeDriverAlerts(prototypeNow);
    await tapText(tester, 'Réessayer');
    expect(find.text('3 non lues'), findsOneWidget);
  });

  testWidgets('the home bell shows the unread alerts and opens them', (tester) async {
    await pumpApp(tester, location: '/missions', profile: driver, alerts: gateway());
    expect(find.bySemanticsLabel('Notifications : 3 alertes non lues'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Notifications : 3 alertes non lues'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertsScreen), findsOneWidget);
  });
}
