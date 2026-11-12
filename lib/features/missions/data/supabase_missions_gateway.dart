import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/mission_flow_config.dart';
import 'missions_gateway.dart';

class SupabaseMissionsGateway implements MissionsGateway {
  SupabaseMissionsGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> myMissions() => _guard(() async {
        final result = await _client.rpc('mes_missions_chauffeur');
        return [for (final row in (result as List? ?? const [])) Map<String, dynamic>.from(row as Map)];
      });

  /// The manager assigns the driver when validating a request: there is no answer step in the database.
  @override
  Future<List<Map<String, dynamic>>> pendingRequests() async => const [];

  @override
  Future<void> respondToRequest({required String missionId, required bool accept, String? reason, String? details}) =>
      throw const MissionsGatewayException(MissionFlowConfig.unavailableMessage);

  @override
  Future<void> reportIncident({
    required String missionId,
    required String kind,
    String? description,
    required bool blocksDeparture,
  }) =>
      throw const MissionsGatewayException(MissionFlowConfig.unavailableMessage);

  @override
  Future<void> recordControl({
    required String id,
    required String missionId,
    required String type,
    required int odometerKm,
    required String fuel,
    required Map<String, String> points,
    String? observations,
    required DateTime enteredAt,
  }) =>
      _guard(() => _client.rpc('enregistrer_controle', params: {
            'p_id': id,
            'p_demande': missionId,
            'p_type': type,
            'p_kilometrage': odometerKm,
            'p_carburant': fuel,
            'p_points': points,
            'p_observations': observations,
            'p_saisi_le': enteredAt.toUtc().toIso8601String(),
          }));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      // Business refusals (P0001 / PT403) carry a French message for the user.
      throw MissionsGatewayException(e.message);
    } on SocketException {
      throw const MissionsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);
    } on TimeoutException {
      throw const MissionsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);
    } on AuthException {
      throw const MissionsGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
