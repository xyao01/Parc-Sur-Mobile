import 'package:parc_sur_mobile/features/profile/data/profile_gateway.dart';

class FakeProfileGateway implements ProfileGateway {
  FakeProfileGateway({
    this.account = const {'phone': '+225 07 00 00 00 00', 'localisation': 'Abidjan, Plateau', 'fonction': 'Agent'},
    this.updateError,
  });

  Map<String, dynamic>? account;
  Object? updateError;
  final updates = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> myAccount(String email) async => account;

  @override
  Future<void> updateMyAccount({
    required String firstName,
    required String lastName,
    required String phone,
    String? location,
  }) async {
    if (updateError != null) throw updateError!;
    updates.add({'prenom': firstName, 'nom': lastName, 'phone': phone, 'localisation': location});
    account = {...?account, 'phone': phone, 'localisation': location};
  }
}
