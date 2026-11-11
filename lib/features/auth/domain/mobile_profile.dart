import '../../../core/app_role.dart';

/// Signed-in user: `profil_mobile()` plus the Supabase Auth account.
class MobileProfile {
  const MobileProfile({
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.email = '',
    this.mustChangePassword = false,
  });

  factory MobileProfile.fromJson(
    Map<String, dynamic> json, {
    String email = '',
    bool mustChangePassword = false,
  }) =>
      MobileProfile(
        firstName: (json['prenom'] as String?)?.trim() ?? '',
        lastName: (json['nom'] as String?)?.trim() ?? '',
        roles: {
          if (json['chauffeur'] == true) AppRole.chauffeur,
          if (json['demandeur'] == true) AppRole.demandeur,
        },
        email: email,
        mustChangePassword: mustChangePassword,
      );

  final String firstName;
  final String lastName;
  final Set<AppRole> roles;
  final String email;

  /// Account still on its provisional (default) password: must choose one first.
  final bool mustChangePassword;

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  String get initials =>
      [firstName, lastName].where((s) => s.isNotEmpty).map((s) => s[0]).join().toUpperCase();

  MobileProfile copyWith({bool? mustChangePassword}) => MobileProfile(
        firstName: firstName,
        lastName: lastName,
        roles: roles,
        email: email,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}
