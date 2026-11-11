import '../data/auth_gateway.dart';
import 'login_failure.dart';
import 'mobile_profile.dart';

/// Mobile sign-in flow, reusing the lockout rules held by the database:
/// check lock → sign in → record failure / success → load mobile profile.
class AuthService {
  AuthService(this._gateway);

  final AuthGateway _gateway;

  /// Throws a [LoginFailure] when sign-in is refused.
  Future<MobileProfile> signIn(String rawEmail, String password) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) throw const MissingFields();

    try {
      final locked = await _gateway.lockedUntil(email);
      if (locked != null) throw AccountLocked(locked);

      try {
        await _gateway.signInWithPassword(email, password);
      } on AuthGatewayException catch (e) {
        if (e.error == AuthGatewayError.invalidCredentials) {
          final lock = await _gateway.recordFailure(email);
          throw lock != null ? AccountLocked(lock) : const InvalidCredentials();
        }
        rethrow;
      }

      await _gateway.recordSuccess();
      final profile = MobileProfile.fromJson(await _gateway.mobileProfile());
      if (profile.roles.isEmpty) {
        await _gateway.signOut();
        throw const NoMobileAccess();
      }
      return profile;
    } on AuthGatewayException catch (e) {
      throw switch (e.error) {
        AuthGatewayError.network => const NetworkFailure(),
        AuthGatewayError.emailNotConfirmed => const EmailNotConfirmed(),
        AuthGatewayError.invalidCredentials => const InvalidCredentials(),
        AuthGatewayError.other => const UnexpectedFailure(),
      };
    }
  }

  Future<void> signOut() => _gateway.signOut();
}
