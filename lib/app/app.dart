import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/parcsur_theme.dart';
import 'router.dart';

class ParcSurApp extends StatefulWidget {
  const ParcSurApp({super.key, this.initialLocation = '/connexion'});

  final String initialLocation;

  @override
  State<ParcSurApp> createState() => _ParcSurAppState();
}

class _ParcSurAppState extends State<ParcSurApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
