import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/app/app.dart';
import 'package:parc_sur_mobile/core/app_role.dart';
import 'package:parc_sur_mobile/core/clock.dart';
import 'package:parc_sur_mobile/features/auth/application/session.dart';
import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';
import 'package:parc_sur_mobile/features/auth/domain/mobile_profile.dart';

import 'fake_auth_gateway.dart';

/// Date of the prototype screens (Tuesday 3 November 2026, 06:00).
final prototypeNow = DateTime(2026, 11, 3, 6);

/// Signed-in user of the prototype screens.
const prototypeProfile = MobileProfile(
  firstName: 'Yao',
  lastName: 'Kouadio',
  roles: {AppRole.chauffeur, AppRole.demandeur},
);

/// Pumps the whole app at [location] on a 390×844 phone (prototype artboard size).
Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  bool signedIn = true,
  AuthGateway? gateway,
  List overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => prototypeNow),
        authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
        initialProfileProvider.overrideWithValue(signedIn ? prototypeProfile : null),
        ...overrides,
      ],
      child: ParcSurApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}
