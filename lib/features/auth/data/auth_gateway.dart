/// Thin port over the backend calls used by sign-in, so the flows in
/// `AuthService` can be tested without Supabase.
abstract interface class AuthGateway {
  /// `blocage_connexion(email)`: end of the current lock, or `null`.
  Future<DateTime?> lockedUntil(String email);

  /// Password sign-in. Throws [AuthGatewayException].
  Future<SignInResult> signInWithPassword(String email, String password);

  /// `echec_connexion(email)`: records a failed attempt, returns the lock end if it triggered one.
  Future<DateTime?> recordFailure(String email);

  /// `connexion_reussie()`: clears the failed attempts of the signed-in user.
  Future<void> recordSuccess();

  /// `profil_mobile()`: first name, last name and mobile roles of the signed-in user.
  Future<Map<String, dynamic>> mobileProfile();

  /// Sets the password and clears the provisional-password markers (same as the web app).
  Future<void> updatePassword(String password);

  /// `journaliser_session(action)`: audit journal entry (`connexion` / `deconnexion`).
  Future<void> logSession(String action);

  Future<void> signOut();
}

class SignInResult {
  const SignInResult({required this.email, required this.provisionalPassword});

  final String email;

  /// `user_metadata.mot_de_passe_provisoire == true`: account created with the default password.
  final bool provisionalPassword;
}

enum AuthGatewayError { invalidCredentials, emailNotConfirmed, samePassword, weakPassword, network, other }

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.error);

  final AuthGatewayError error;

  @override
  String toString() => 'AuthGatewayException($error)';
}
