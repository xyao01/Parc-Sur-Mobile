/// Mobile profiles covered by the prototype.
enum AppRole { chauffeur, demandeur }

/// Configurable parameters of mobile sign-in (see README, « Points ouverts »).
abstract final class AuthConfig {
  /// Home shown first when a user is both chauffeur and demandeur.
  static const preferredRole = AppRole.chauffeur;

  /// Failed attempts before lock. Mirrors `parametres_connexion()` in the
  /// database (not callable before sign-in); only used in the lock message.
  static const maxFailedAttempts = 5;

  /// Where the reset link of the e-mail sends the user back: this app (deep link declared in
  /// `AndroidManifest.xml`). Overridable with `passwordResetRedirect` in `.env`. Must be listed in
  /// Supabase › Authentication › URL Configuration › Redirect URLs, otherwise Supabase sends the
  /// user to the Site URL (web app) instead.
  static const passwordResetRedirect = 'com.syabetech.parcsur://reinitialiser-mot-de-passe';

  /// Validity of the reset link, as set in Supabase Auth (shown in the messages only).
  static const resetLinkValidityHours = 1;
}

/// Home route for a signed-in user's roles.
String homeRouteFor(Set<AppRole> roles) {
  final role = roles.contains(AuthConfig.preferredRole) ? AuthConfig.preferredRole : roles.first;
  return switch (role) {
    AppRole.chauffeur => '/missions',
    AppRole.demandeur => '/demandes/nouvelle',
  };
}
