import '../../../core/app_role.dart';
import '../../../core/french_dates.dart';

/// Why a sign-in attempt was refused, with the message shown to the user.
sealed class LoginFailure implements Exception {
  const LoginFailure();

  String get message;
}

class MissingFields extends LoginFailure {
  const MissingFields();

  @override
  String get message => 'Saisissez votre adresse e-mail et votre mot de passe.';
}

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
