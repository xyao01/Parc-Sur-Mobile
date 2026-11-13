import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../missions/domain/mission_flow_config.dart';
import 'requests_gateway.dart';

/// Same columns as the web app (`demandes.supabase.ts`).
const _columns =
    'id, numero, demandeur_id, motif, destination, depart, retour, passagers, avec_chauffeur, commentaire, statut, '
    'vehicule, chauffeur, motif_refus, motif_annulation, decide_le, created_at';

class SupabaseRequestsGateway implements RequestsGateway {
  SupabaseRequestsGateway(this._client);

  final SupabaseClient _client;

  Future<String> _me() async {
    final id = await _client.rpc('utilisateur_courant');
    if (id is! String) throw const RequestsGatewayException('Ce compte n’a pas accès aux demandes de véhicule.');
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> myRequests() => _guard(() async {
        // A manager also reads every request through demande_vue: keep the requester's own.
        final me = await _me();
        final rows = await _client
            .from('demande_vue')
            .select(_columns)
            .eq('demandeur_id', me)
            .order('created_at', ascending: false)
            .limit(200);
        return [for (final r in rows) Map<String, dynamic>.from(r)];
      });

  @override
  Future<String> create(Map<String, dynamic> row) => _guard(() async {
        final me = await _me();
        final r = await _client.from('demande_vehicule').insert({...row, 'demandeur_id': me}).select('id').single();
        return r['id'] as String;
      });

  @override
  Future<void> update(String id, Map<String, dynamic> row) => _guard(() async {
        final rows = await _client.from('demande_vehicule').update(row).eq('id', id).select('id');
        if (rows.isEmpty) {
          throw const RequestsGatewayException('Seule une demande en attente se modifie, par son demandeur.');
        }
      });

  @override
  Future<void> cancel(String id, String reason) =>
      _guard(() => _client.rpc('annuler_demande', params: {'p_id': id, 'p_motif': reason}));

  @override
  Future<void> reportProblem({required String requestId, required String kind, String? description}) =>
      throw const RequestsGatewayException(MissionFlowConfig.unavailableMessage);

  @override
  Future<void> rate({required String requestId, required int rating, required List<String> tags, String? comment}) =>
      throw const RequestsGatewayException(MissionFlowConfig.unavailableMessage);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      // Business refusals of the trigger / functions carry a French message for the user.
      throw RequestsGatewayException(e.message);
    } on http.ClientException {
      throw const RequestsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on SocketException {
      throw const RequestsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on TimeoutException {
      throw const RequestsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.');
    } on AuthException {
      throw const RequestsGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
