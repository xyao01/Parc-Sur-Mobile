import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_gateway.dart';

class SupabaseProfileGateway implements ProfileGateway {
  SupabaseProfileGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> myAccount(String email) => _guard(() async {
        final row = await _client
            .from('utilisateur')
            .select('phone, localisation, profile:profils_id (libelle)')
            .ilike('email', email.trim())
            .isFilter('deleted_at', null)
            .maybeSingle();
        if (row == null) return null;
        final profile = row['profile'];
        return {
          'phone': row['phone'],
          'localisation': row['localisation'],
          'fonction': profile is Map ? profile['libelle'] : null,
        };
      });

  @override
  Future<void> updateMyAccount({
    required String firstName,
    required String lastName,
    required String phone,
    String? location,
  }) =>
      _guard(() => _client.rpc('modifier_mon_compte', params: {
            'p_prenom': firstName,
            'p_nom': lastName,
            'p_phone': phone,
            'p_localisation': location,
          }));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw ProfileGatewayException(e.message);
    } on http.ClientException {
      throw const ProfileGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on SocketException {
      throw const ProfileGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on TimeoutException {
      throw const ProfileGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on AuthException {
      throw const ProfileGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
