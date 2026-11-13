import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/parcsur_theme.dart';
import '../features/auth/application/session.dart';
import 'router.dart';
import 'routes.dart';
import 'sync.dart';

class ParcSurApp extends ConsumerStatefulWidget {
  const ParcSurApp({super.key, this.initialLocation = loginRoute});

  final String initialLocation;

  @override
  ConsumerState<ParcSurApp> createState() => _ParcSurAppState();
}

class _ParcSurAppState extends ConsumerState<ParcSurApp> {
  late final GoRouter _router = buildRouter(ref, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sends the entries kept on the phone at start and when the network comes back (l2-mob-04).
    ref.watch(syncProvider);
    // The reset link of the e-mail reopens the app: show the reset page (new password or « Lien expiré »).
    ref.listen(passwordRecoveryProvider, (_, status) {
      if (status == RecoveryStatus.ready || status == RecoveryStatus.invalid) _router.go(Routes.resetPassword);
    });
    return MaterialApp.router(
      title: 'ParcSûr',
      debugShowCheckedModeBanner: false,
      theme: buildParcSurTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}
