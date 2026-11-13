import 'package:parc_sur_mobile/features/profile/data/profile_gateway.dart';

class FakeProfileGateway implements ProfileGateway {
  FakeProfileGateway({
    this.account = const {'phone': '+225 07 00 00 00 00', 'localisation': 'Abidjan, Plateau', 'fonction': 'Agent'},
    this.updateError,
    this.driverRecord = const {
      'telephone': '+225 05 11 22 33 44',
      'permis': ['B', 'C'],
      'finValidite': '2027-03-12',
    },
    this.driverError,
  });

  Map<String, dynamic>? account;
  Object? updateError;
  Map<String, dynamic>? driverRecord;
  Object? driverError;
  final updates = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> myAccount(String email) async => account;

  @override
  Future<Map<String, dynamic>?> myDriverRecord() async {
    if (driverError != null) throw driverError!;
    return driverRecord;
  }

  final driverUpdates = <Map<String, dynamic>>[];

  @override
  Future<void> updateMyDriverRecord({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    if (updateError != null) throw updateError!;
    driverUpdates.add({'prenom': firstName, 'nom': lastName, 'phone': phone});
    driverRecord = {...?driverRecord, 'prenom': firstName, 'nom': lastName, 'telephone': phone};
  }

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
