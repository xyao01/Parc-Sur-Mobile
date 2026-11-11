import 'package:parc_sur_mobile/features/auth/data/auth_gateway.dart';

/// In-memory [AuthGateway] recording the calls made by [AuthService].
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.lockedUntilValue,
    this.signInError,
    this.lockAfterFailure,
    this.provisionalPassword = false,
    this.updatePasswordError,
    this.profile = const {'prenom': 'Yao', 'nom': 'Kouadio', 'demandeur': false, 'chauffeur': true},
  });

  DateTime? lockedUntilValue;
  AuthGatewayError? signInError;
  DateTime? lockAfterFailure;
  bool provisionalPassword;
  AuthGatewayError? updatePasswordError;
  Map<String, dynamic> profile;

  final calls = <String>[];

  @override
  Future<DateTime?> lockedUntil(String email) async {
    calls.add('lockedUntil:$email');
    return lockedUntilValue;
  }

  @override
  Future<SignInResult> signInWithPassword(String email, String password) async {
    calls.add('signIn:$email');
    if (signInError != null) throw AuthGatewayException(signInError!);
    return SignInResult(email: email, provisionalPassword: provisionalPassword);
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
  Future<void> updatePassword(String password) async {
    calls.add('updatePassword:$password');
    if (updatePasswordError != null) throw AuthGatewayException(updatePasswordError!);
  }

  @override
  Future<void> logSession(String action) async => calls.add('logSession:$action');

  @override
  Future<void> signOut() async => calls.add('signOut');
}
