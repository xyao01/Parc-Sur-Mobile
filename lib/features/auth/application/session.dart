import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_role.dart';
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

/// Deep link the reset e-mail returns to (`AuthConfig.passwordResetRedirect`, or `.env`).
final passwordResetRedirectProvider = Provider<String>((ref) => AuthConfig.passwordResetRedirect);

/// Where the « mot de passe oublié » flow stands on this device.
enum RecoveryStatus {
  /// No reset link opened (the reset page then shows « Lien expiré »).
  none,

  /// Link opened: a recovery session lets the user choose a new password.
  ready,

  /// Link expired or already used.
  invalid,

  /// New password saved; the user signs in with it.
  done,
}

final passwordRecoveryProvider = NotifierProvider<PasswordRecoveryNotifier, RecoveryStatus>(
  PasswordRecoveryNotifier.new,
);

class PasswordRecoveryNotifier extends Notifier<RecoveryStatus> {
  @override
  RecoveryStatus build() {
    final sub = ref.watch(authGatewayProvider).recoveryLinks.listen((link) {
      state = link == RecoveryLink.opened ? RecoveryStatus.ready : RecoveryStatus.invalid;
    });
    ref.onDispose(sub.cancel);
    return RecoveryStatus.none;
  }

  /// Throws a `LoginFailure` when refused.
  Future<void> resetPassword(String password, String confirmation) async {
    await ref.read(authServiceProvider).resetPassword(password, confirmation);
    state = RecoveryStatus.done;
  }

  /// Leaves the flow (back to sign-in, or a new link requested).
  void clear() => state = RecoveryStatus.none;
}
