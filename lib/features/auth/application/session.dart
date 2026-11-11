import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_gateway.dart';
import '../data/supabase_auth_gateway.dart';
import '../domain/auth_service.dart';
import '../domain/mobile_profile.dart';

final authGatewayProvider = Provider<AuthGateway>((ref) => SupabaseAuthGateway(Supabase.instance.client));

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(authGatewayProvider)));

/// Profile the app starts with (`null` = signed out). Overridden in tests.
final initialProfileProvider = Provider<MobileProfile?>((ref) => null);

/// Signed-in user for this app session, `null` when signed out.
final sessionProvider = NotifierProvider<SessionNotifier, MobileProfile?>(SessionNotifier.new);

class SessionNotifier extends Notifier<MobileProfile?> {
  @override
  MobileProfile? build() => ref.watch(initialProfileProvider);

  /// Throws a `LoginFailure` when refused.
  Future<MobileProfile> signIn(String email, String password) async {
    final profile = await ref.read(authServiceProvider).signIn(email, password);
    state = profile;
    return profile;
  }

  /// First sign-in password. Throws a `LoginFailure` when refused.
  Future<void> setPassword(String password, String confirmation) async {
    await ref.read(authServiceProvider).setPassword(password, confirmation);
    state = state?.copyWith(mustChangePassword: false);
  }

  Future<void> signOut() async {
    final profile = state;
    state = null;
    await ref.read(authServiceProvider).signOut(profile);
  }
}
