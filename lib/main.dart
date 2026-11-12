import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/auth/application/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `.env` (not versioned) holds the Supabase URL and publishable key; see `.env.example`.
  await dotenv.load();
  // Also opens the recovery session when the reset link of the e-mail reopens the app (deep link).
  await Supabase.initialize(
    url: dotenv.env['supabaseUrl']!,
    publishableKey: dotenv.env['supabaseKey']!,
  );
  final resetRedirect = dotenv.env['passwordResetRedirect'];
  runApp(ProviderScope(
    overrides: [
      if (resetRedirect != null && resetRedirect.isNotEmpty)
        passwordResetRedirectProvider.overrideWithValue(resetRedirect),
    ],
    child: const ParcSurApp(),
  ));
}
