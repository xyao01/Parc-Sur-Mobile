/// Password policy, identical to the web app (`POLITIQUE_MOT_DE_PASSE`):
/// 8 characters minimum, including one uppercase letter and one digit.
abstract final class PasswordPolicy {
  static const minLength = 8;

  static List<({String label, bool ok})> criteria(String password) => [
        (label: '$minLength caractères minimum', ok: password.length >= minLength),
        (label: 'Une majuscule', ok: RegExp('[A-Z]').hasMatch(password)),
        (label: 'Un chiffre', ok: RegExp(r'\d').hasMatch(password)),
      ];

  static bool isValid(String password) => criteria(password).every((c) => c.ok);
}
