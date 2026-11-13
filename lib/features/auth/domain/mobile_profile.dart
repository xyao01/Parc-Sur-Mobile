import '../../../core/app_role.dart';

/// Signed-in user: `profil_mobile()` plus the Supabase Auth account.
class MobileProfile {
  const MobileProfile({
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.email = '',
    this.mustChangePassword = false,
    this.hasAssignedVehicle = false,
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
        hasAssignedVehicle: json['vehiculeAffecte'] == true,
      );

  /// Kept on the phone to reopen the session without network (l2-mob-04).
  Map<String, dynamic> toCache() => {
        'prenom': firstName,
        'nom': lastName,
        'chauffeur': roles.contains(AppRole.chauffeur),
        'demandeur': roles.contains(AppRole.demandeur),
        'vehiculeAffecte': hasAssignedVehicle,
        'email': email,
        'provisoire': mustChangePassword,
      };

  static MobileProfile fromCache(Map<String, dynamic> j) => MobileProfile.fromJson(
        j,
        email: (j['email'] as String?) ?? '',
        mustChangePassword: j['provisoire'] == true,
      );

  final String firstName;
  final String lastName;
  final Set<AppRole> roles;
  final String email;

  /// Account still on its provisional (default) password: must choose one first.
  final bool mustChangePassword;

  /// `profil_mobile().vehiculeAffecte`: an agent with a vehicle assigned (monthly reading, l2-km-02).
  final bool hasAssignedVehicle;

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  String get initials =>
      [firstName, lastName].where((s) => s.isNotEmpty).map((s) => s[0]).join().toUpperCase();

  MobileProfile copyWith({bool? mustChangePassword, String? firstName, String? lastName}) => MobileProfile(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        roles: roles,
        email: email,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        hasAssignedVehicle: hasAssignedVehicle,
      );
}
