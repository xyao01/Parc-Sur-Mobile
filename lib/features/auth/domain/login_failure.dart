import '../../../core/app_role.dart';
import '../../../core/french_dates.dart';

/// Why a sign-in or password change was refused, with the message shown to the user.
sealed class LoginFailure implements Exception {
  const LoginFailure();

  String get message;
}

class MissingFields extends LoginFailure {
  const MissingFields();

  @override
  String get message => 'Saisissez votre adresse e-mail et votre mot de passe.';
}

/// Same wording as the web app.
class InvalidCredentials extends LoginFailure {
  const InvalidCredentials();

  @override
  String get message => 'Adresse e-mail ou mot de passe incorrect.';
}

class AccountLocked extends LoginFailure {
  const AccountLocked(this.until);

  final DateTime until;

  /// Copy from the web prototype « Connexion – blocage ».
  @override
  String get message =>
      'Compte bloqué après ${AuthConfig.maxFailedAttempts} tentatives échouées. '
      'Réessayez à partir de ${FrenchDates.time(until.toLocal())}.';
}

class EmailNotConfirmed extends LoginFailure {
  const EmailNotConfirmed();

  @override
  String get message => "Compte non activé : ouvrez le lien d'invitation reçu par e-mail.";
}

class NoMobileAccess extends LoginFailure {
  const NoMobileAccess();

  @override
  String get message => "Ce compte n'a pas accès à l'application mobile. Contactez l'administrateur de ParcSûr.";
}

class NetworkFailure extends LoginFailure {
  const NetworkFailure();

  @override
  String get message => 'Connexion impossible. Vérifiez votre réseau et réessayez.';
}

class UnexpectedFailure extends LoginFailure {
  const UnexpectedFailure();

  @override
  String get message => 'Une erreur est survenue. Réessayez dans un instant.';
}

// New password (web app wording).

class PasswordPolicyFailure extends LoginFailure {
  const PasswordPolicyFailure();

  @override
  String get message => 'Le mot de passe doit contenir au moins 8 caractères, dont une majuscule et un chiffre.';
}

class PasswordMismatch extends LoginFailure {
  const PasswordMismatch();

  @override
  String get message => 'Les deux mots de passe ne sont pas identiques.';
}

class SamePassword extends LoginFailure {
  const SamePassword();

  @override
  String get message => 'Choisissez un mot de passe différent de l’actuel.';
}

class WeakPassword extends LoginFailure {
  const WeakPassword();

  @override
  String get message => 'Ce mot de passe ne respecte pas la politique de sécurité.';
}

class PasswordNotSaved extends LoginFailure {
  const PasswordNotSaved();

  @override
  String get message => 'Le mot de passe n’a pas pu être enregistré. Reconnectez-vous puis réessayez.';
}
