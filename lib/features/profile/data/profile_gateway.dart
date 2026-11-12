/// Port over the « Mon compte » calls of the Profile (Mob-P01).
abstract interface class ProfileGateway {
  /// Own `utilisateur` row (RLS: the signed-in web account): `phone`, `localisation`, `fonction`.
  /// `null` for an account without web record (driver only).
  Future<Map<String, dynamic>?> myAccount(String email);

  /// `modifier_mon_compte(prenom, nom, phone, localisation)`.
  Future<void> updateMyAccount({
    required String firstName,
    required String lastName,
    required String phone,
    String? location,
  });
}

class ProfileGatewayException implements Exception {
  const ProfileGatewayException(this.message);

  final String message;

  @override
  String toString() => 'ProfileGatewayException($message)';
}
