/// Thin port over the backend calls used by sign-in, so the flows in
/// `AuthService` can be tested without Supabase.
abstract interface class AuthGateway {
  /// Account of the session Supabase kept from a previous launch, or `null`.
  Future<SignInResult?> currentAccount();

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

  /// Supabase Auth `recover`: e-mails a reset link (sent by the `auth-email-hook` function)
  /// that reopens the app at [redirectTo].
  Future<void> requestPasswordReset(String email, {required String redirectTo});

  /// Reset links opened from the e-mail: a recovery session is open, or the link is expired / already used.
  Stream<RecoveryLink> get recoveryLinks;
}

enum RecoveryLink { opened, invalid }

class SignInResult {
  const SignInResult({required this.email, required this.provisionalPassword});

  final String email;

  /// `user_metadata.mot_de_passe_provisoire == true`: account created with the default password.
  final bool provisionalPassword;
}

enum AuthGatewayError { invalidCredentials, emailNotConfirmed, samePassword, weakPassword, rateLimited, network, other }

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.error);

  final AuthGatewayError error;

  @override
  String toString() => 'AuthGatewayException($error)';
}
