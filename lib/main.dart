import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/routes.dart';
import 'core/app_role.dart';
import 'features/auth/application/session.dart';
import 'features/auth/data/supabase_auth_gateway.dart';
import 'features/auth/domain/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `.env` (not versioned) holds the Supabase URL and publishable key; see `.env.example`.
  await dotenv.load();
  // Also opens the recovery session when the reset link of the e-mail reopens the app (deep link).
  await Supabase.initialize(
    url: dotenv.env['supabaseUrl']!,
    publishableKey: dotenv.env['supabaseKey']!,
  );
  // Session kept by Supabase from the previous launch: no new sign-in needed.
  final profile = await AuthService(SupabaseAuthGateway(Supabase.instance.client)).restore();
  final start = profile == null
      ? Routes.login
      : (profile.mustChangePassword ? Routes.newPassword : homeRouteFor(profile.roles));
  final resetRedirect = dotenv.env['passwordResetRedirect'];
  runApp(ProviderScope(
    overrides: [
      initialProfileProvider.overrideWithValue(profile),
      if (resetRedirect != null && resetRedirect.isNotEmpty)
        passwordResetRedirectProvider.overrideWithValue(resetRedirect),
    ],
    child: ParcSurApp(initialLocation: start),
  ));
}
