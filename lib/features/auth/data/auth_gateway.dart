/// Thin port over the backend calls used by sign-in, so the flow in
/// `AuthService` can be tested without Supabase.
abstract interface class AuthGateway {
  /// `blocage_connexion(email)`: end of the current lock, or `null`.
  Future<DateTime?> lockedUntil(String email);

  /// Password sign-in. Throws [AuthGatewayException].
  Future<void> signInWithPassword(String email, String password);

  /// `echec_connexion(email)`: records a failed attempt, returns the lock end if it triggered one.
  Future<DateTime?> recordFailure(String email);

  /// `connexion_reussie()`: clears the failed attempts of the signed-in user.
  Future<void> recordSuccess();

  /// `profil_mobile()`: first name, last name and mobile roles of the signed-in user.
  Future<Map<String, dynamic>> mobileProfile();

  Future<void> signOut();
}

enum AuthGatewayError { invalidCredentials, emailNotConfirmed, network, other }

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.error);

  final AuthGatewayError error;

  @override
  String toString() => 'AuthGatewayException($error)';
}
