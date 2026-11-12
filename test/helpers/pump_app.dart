import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/app/app.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/core/clock.dart';
import 'package:parc_sur_mobile/features/auth/application/session.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';
import 'package:parc_sur_mobile/features/alerts/data/alerts_gateway.dart';
import 'package:parc_sur_mobile/features/alerts/data/alerts_providers.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_gateway.dart';
import 'package:parc_sur_mobile/features/missions/data/missions_providers.dart';

import 'fake_alerts_gateway.dart';
import 'fake_auth_gateway.dart';
import 'fake_missions_gateway.dart';

/// Date of the prototype screens (Tuesday 3 November 2026, 06:00).
final prototypeNow = DateTime(2026, 11, 3, 6);

/// Signed-in user of the prototype screens.
const prototypeProfile = MobileProfile(
  firstName: 'Yao',
  lastName: 'Kouadio',
  email: 'yao.kouadio@ministere.ci',
  roles: {AppRole.chauffeur, AppRole.demandeur},
);

/// Pumps the whole app at [location] on a 390×844 phone (prototype artboard size).
Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  bool signedIn = true,
  MobileProfile profile = prototypeProfile,
  AuthGateway? gateway,
  MissionsGateway? missions,
  AlertsGateway? alerts,
  DateTime? now,
  List overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now ?? prototypeNow),
        authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
        missionsGatewayProvider.overrideWithValue(
          missions ?? FakeMissionsGateway(rows: prototypeMissionRows(prototypeNow)),
        ),
        alertsGatewayProvider.overrideWithValue(alerts ?? FakeAlertsGateway()),
        initialProfileProvider.overrideWithValue(signedIn ? profile : null),
        ...overrides,
      ],
      child: ParcSurApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}
