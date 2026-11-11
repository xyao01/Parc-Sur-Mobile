import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

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
  Future<void> signInWithPassword(String email, String password) => _guard(() async {
        await _client.auth.signInWithPassword(email: email, password: password);
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
        _ => e.statusCode == '400' ? AuthGatewayError.invalidCredentials : AuthGatewayError.other,
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
