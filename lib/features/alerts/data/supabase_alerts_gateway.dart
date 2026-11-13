import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'alerts_gateway.dart';

class SupabaseAlertsGateway implements AlertsGateway {
  SupabaseAlertsGateway(this._client);

  final SupabaseClient _client;

  /// Most recent alerts loaded per audience.
  static const limit = 50;

  @override
  Future<List<Map<String, dynamic>>> driverAlerts() => _guard(() async {
        final result = await _client.rpc('mes_notifications_chauffeur', params: {'p_limite': limit});
        return [for (final row in (result as List? ?? const [])) Map<String, dynamic>.from(row as Map)];
      });

  @override
  Future<void> markDriverAlertsRead(List<String>? ids) =>
      _guard(() => _client.rpc('marquer_notifications_chauffeur_lues', params: {'p_ids': ids}));

  @override
  Future<List<Map<String, dynamic>>> requesterAlerts() => _guard(() async {
        final rows = await _client
            .from('notification')
            .select('id, titre, message, lien, created_at, lue_le')
            .order('created_at', ascending: false)
            .limit(limit);
        return [
          for (final r in rows)
            {
              'id': r['id'],
              'titre': r['titre'],
              'message': r['message'],
              'lien': r['lien'],
              'creeLe': r['created_at'],
              'lueLe': r['lue_le'],
            },
        ];
      });

  @override
  Future<void> markRequesterAlertsRead(List<String>? ids) => _guard(() async {
        final update = _client
            .from('notification')
            .update({'lue_le': DateTime.now().toUtc().toIso8601String()})
            .isFilter('lue_le', null);
        await (ids == null ? update : update.inFilter('id', ids));
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw AlertsGatewayException(e.message);
    } on http.ClientException {
      throw const AlertsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on SocketException {
      throw const AlertsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on TimeoutException {
      throw const AlertsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on AuthException {
      throw const AlertsGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
