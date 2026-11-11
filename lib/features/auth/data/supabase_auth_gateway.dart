import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

/// User metadata keys shared with the web app (`auth.supabase.ts`).
const metaProvisionalPassword = 'mot_de_passe_provisoire';
const metaDefaultPassword = 'mot_de_passe_par_defaut';

/// [AuthGateway] backed by Supabase Auth and the `public` sign-in functions.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  static DateTime? _parseDate(Object? value) => value is String ? DateTime.parse(value) : null;

  @override
  Future<DateTime?> lockedUntil(String email) => _guard(() async {
        return _parseDate(await _client.rpc('blocage_connexion', params: {'p_email': email}));
      });

  @override
  Future<SignInResult> signInWithPassword(String email, String password) => _guard(() async {
        final res = await _client.auth.signInWithPassword(email: email, password: password);
        final user = res.user;
        if (user == null) throw const AuthGatewayException(AuthGatewayError.other);
        return SignInResult(
          email: user.email ?? email,
          provisionalPassword: user.userMetadata?[metaProvisionalPassword] == true,
        );
      });

  @override
  Future<DateTime?> recordFailure(String email) => _guard(() async {
        return _parseDate(await _client.rpc('echec_connexion', params: {'p_email': email}));
      });

  @override
  Future<void> recordSuccess() => _guard(() => _client.rpc('connexion_reussie'));

  @override
  Future<Map<String, dynamic>> mobileProfile() => _guard(() async {
        final result = await _client.rpc('profil_mobile');
        return Map<String, dynamic>.from(result as Map);
      });

  @override
  Future<void> updatePassword(String password) => _guard(() async {
        await _client.auth.updateUser(UserAttributes(
          password: password,
          data: {metaProvisionalPassword: false, metaDefaultPassword: null},
        ));
      });

  @override
  Future<void> logSession(String action) =>
      _guard(() => _client.rpc('journaliser_session', params: {'p_action': action}));

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AuthRetryableFetchException {
      throw const AuthGatewayException(AuthGatewayError.network);
    } on AuthException catch (e) {
      final error = switch (e.code) {
        'invalid_credentials' => AuthGatewayError.invalidCredentials,
        'email_not_confirmed' => AuthGatewayError.emailNotConfirmed,
        'same_password' => AuthGatewayError.samePassword,
        'weak_password' => AuthGatewayError.weakPassword,
        _ => AuthGatewayError.other,
      };
      throw AuthGatewayException(error);
    } on SocketException {
      throw const AuthGatewayException(AuthGatewayError.network);
    } on TimeoutException {
      throw const AuthGatewayException(AuthGatewayError.network);
    } on PostgrestException {
      throw const AuthGatewayException(AuthGatewayError.other);
    }
  }
}
