import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';

/// In-memory [AuthGateway] recording the calls made by [AuthService].
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.lockedUntilValue,
    this.signInError,
    this.lockAfterFailure,
    this.profile = const {'prenom': 'Yao', 'nom': 'Kouadio', 'demandeur': false, 'chauffeur': true},
  });

  DateTime? lockedUntilValue;
  AuthGatewayError? signInError;
  DateTime? lockAfterFailure;
  Map<String, dynamic> profile;

  final calls = <String>[];

  @override
  Future<DateTime?> lockedUntil(String email) async {
    calls.add('lockedUntil:$email');
    return lockedUntilValue;
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    calls.add('signIn:$email');
    if (signInError != null) throw AuthGatewayException(signInError!);
  }

  @override
  Future<DateTime?> recordFailure(String email) async {
    calls.add('recordFailure:$email');
    return lockAfterFailure;
  }

  @override
  Future<void> recordSuccess() async => calls.add('recordSuccess');

  @override
  Future<Map<String, dynamic>> mobileProfile() async {
    calls.add('mobileProfile');
    return profile;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');
}
