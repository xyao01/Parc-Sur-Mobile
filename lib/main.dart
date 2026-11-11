import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `.env` (not versioned) holds the Supabase URL and publishable key; see `.env.example`.
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['supabaseUrl']!,
    publishableKey: dotenv.env['supabaseKey']!,
  );
  runApp(const ProviderScope(child: ParcSurApp()));
}
