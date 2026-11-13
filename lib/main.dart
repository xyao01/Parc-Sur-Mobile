import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/routes.dart';
import 'core/app_role.dart';
import 'core/offline/local_store.dart';
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
  // Entries kept offline and caches survive the app being closed (l2-mob-04).
  final store = SharedPreferencesStore(await SharedPreferences.getInstance());
  // Session kept by Supabase from the previous launch: no new sign-in needed.
  // Without network, the last profile kept on the phone reopens it.
  final profile = await AuthService(SupabaseAuthGateway(Supabase.instance.client)).restore() ??
      (Supabase.instance.client.auth.currentSession != null ? cachedProfile(store) : null);
  final start = profile == null
      ? Routes.login
      : (profile.mustChangePassword ? Routes.newPassword : homeRouteFor(profile.roles));
  if (profile != null) await store.write('cache.profil.v1', jsonEncode(profile.toCache()));
  final resetRedirect = dotenv.env['passwordResetRedirect'];
  runApp(ProviderScope(
    overrides: [
      initialProfileProvider.overrideWithValue(profile),
      localStoreProvider.overrideWithValue(store),
      if (resetRedirect != null && resetRedirect.isNotEmpty)
        passwordResetRedirectProvider.overrideWithValue(resetRedirect),
    ],
    child: ParcSurApp(initialLocation: start),
  ));
}
