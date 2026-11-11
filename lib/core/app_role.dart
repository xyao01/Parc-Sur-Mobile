/// Mobile profiles covered by the prototype.
enum AppRole { chauffeur, demandeur }

/// Configurable parameters of mobile sign-in (see README, « Points ouverts »).
abstract final class AuthConfig {
  /// Home shown first when a user is both chauffeur and demandeur.
  static const preferredRole = AppRole.chauffeur;

  /// Failed attempts before lock. Mirrors `parametres_connexion()` in the
  /// database (not callable before sign-in); only used in the lock message.
  static const maxFailedAttempts = 5;
}

/// Home route for a signed-in user's roles.
String homeRouteFor(Set<AppRole> roles) {
  final role = roles.contains(AuthConfig.preferredRole) ? AuthConfig.preferredRole : roles.first;
  return switch (role) {
    AppRole.chauffeur => '/missions',
    AppRole.demandeur => '/demandes/nouvelle',
  };
}
