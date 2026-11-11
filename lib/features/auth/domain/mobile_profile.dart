import '../../../core/app_role.dart';

/// Signed-in user as returned by the `profil_mobile()` database function.
class MobileProfile {
  const MobileProfile({required this.firstName, required this.lastName, required this.roles});

  factory MobileProfile.fromJson(Map<String, dynamic> json) => MobileProfile(
        firstName: (json['prenom'] as String?)?.trim() ?? '',
        lastName: (json['nom'] as String?)?.trim() ?? '',
        roles: {
          if (json['chauffeur'] == true) AppRole.chauffeur,
          if (json['demandeur'] == true) AppRole.demandeur,
        },
      );

  final String firstName;
  final String lastName;
  final Set<AppRole> roles;

  String get initials =>
      [firstName, lastName].where((s) => s.isNotEmpty).map((s) => s[0]).join().toUpperCase();
}
