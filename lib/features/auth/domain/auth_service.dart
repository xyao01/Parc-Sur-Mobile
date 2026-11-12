import '../../../core/app_role.dart';
import '../data/auth_gateway.dart';
import 'login_failure.dart';
import 'mobile_profile.dart';
import 'password_policy.dart';

/// Mobile sign-in flows, reusing the rules held by the database and the web app:
/// check lock → sign in → (failure: record it) → load mobile profile → record success.
class AuthService {
  AuthService(this._gateway);

  final AuthGateway _gateway;

  /// Throws a [LoginFailure] when sign-in is refused.
  Future<MobileProfile> signIn(String rawEmail, String password) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) throw const MissingFields();

    return _mapErrors(() async {
      final locked = await _gateway.lockedUntil(email);
      if (locked != null) throw AccountLocked(locked);

      final SignInResult account;
      try {
        account = await _gateway.signInWithPassword(email, password);
      } on AuthGatewayException catch (e) {
        if (e.error == AuthGatewayError.invalidCredentials) {
          final lock = await _gateway.recordFailure(email);
          throw lock != null ? AccountLocked(lock) : const InvalidCredentials();
        }
        rethrow;
      }

      // Profile first: connexion_reussie is refused by the API to accounts with no mobile role.
      final profile = MobileProfile.fromJson(
        await _gateway.mobileProfile(),
        email: account.email,
        mustChangePassword: account.provisionalPassword,
      );
      if (profile.roles.isEmpty) {
        await _gateway.signOut();
        throw const NoMobileAccess();
      }
      await _gateway.recordSuccess();
      await _logSession(profile, 'connexion');
      return profile;
    });
  }

  /// « Mot de passe oublié » (web `demanderReinitialisation`): unknown accounts get the
  /// same answer as a successful send; only the send limit and the network are reported.
  Future<void> requestPasswordReset(String rawEmail, {required String redirectTo}) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty) throw const MissingEmail();
    try {
      await _gateway.requestPasswordReset(email, redirectTo: redirectTo);
    } on AuthGatewayException catch (e) {
      if (e.error == AuthGatewayError.rateLimited) throw const TooManyResetRequests();
      if (e.error == AuthGatewayError.network) throw const NetworkFailure();
    }
  }

  /// Reset link opened: saves the new password, then closes the recovery session so
  /// the user signs in with it (web `reinitialiserMotDePasse`). Throws a [LoginFailure].
  Future<void> resetPassword(String password, String confirmation) async {
    await setPassword(password, confirmation);
    await signOut(null);
  }

  /// First sign-in: replaces the provisional password. Throws a [LoginFailure].
  Future<void> setPassword(String password, String confirmation) async {
    if (!PasswordPolicy.isValid(password)) throw const PasswordPolicyFailure();
    if (password != confirmation) throw const PasswordMismatch();
    try {
      await _gateway.updatePassword(password);
    } on AuthGatewayException catch (e) {
      throw switch (e.error) {
        AuthGatewayError.samePassword => const SamePassword(),
        AuthGatewayError.weakPassword => const WeakPassword(),
        AuthGatewayError.network => const NetworkFailure(),
        _ => const PasswordNotSaved(),
      };
    }
  }

  Future<void> signOut(MobileProfile? profile) async {
    if (profile != null) await _logSession(profile, 'deconnexion');
    try {
      await _gateway.signOut();
    } on AuthGatewayException {
      // Local session is dropped anyway; nothing to show the user.
    }
  }

  /// Audit journal, as the web app does. Only accounts with a `utilisateur`
  /// record (demandeurs) may write it; best effort, never blocks the flow.
  Future<void> _logSession(MobileProfile profile, String action) async {
    if (!profile.roles.contains(AppRole.demandeur)) return;
    try {
      await _gateway.logSession(action);
    } on AuthGatewayException {
      // Ignored on purpose.
    }
  }

  Future<T> _mapErrors<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthGatewayException catch (e) {
      throw switch (e.error) {
        AuthGatewayError.network => const NetworkFailure(),
        AuthGatewayError.emailNotConfirmed => const EmailNotConfirmed(),
        AuthGatewayError.invalidCredentials => const InvalidCredentials(),
        _ => const UnexpectedFailure(),
      };
    }
  }
}
