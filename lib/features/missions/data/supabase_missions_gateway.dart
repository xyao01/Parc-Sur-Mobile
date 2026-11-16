import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
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

  @override
  Future<void> uploadTicket({required String localPath, required String remotePath}) => _guard(() async {
        try {
          await _client.storage.from(ticketBucket).upload(
                remotePath,
                File(localPath),
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
        } on StorageException catch (e) {
          // Sent before the network dropped: the copy on the server is the same photo.
          if (e.statusCode == '409' || e.message.toLowerCase().contains('exists')) return;
          throw MissionsGatewayException(e.message);
        }
      });

  @override
  Future<void> recordFuel({
    required String id,
    required String missionId,
    required int odometerKm,
    required double litres,
    required int amount,
    required bool full,
    String? station,
    required List<String> tickets,
    required DateTime enteredAt,
  }) =>
      _guard(() => _client.rpc('saisir_plein_chauffeur', params: {
            'p_id': id,
            'p_demande': missionId,
            'p_kilometrage': odometerKm,
            'p_litres': litres,
            'p_montant': amount,
            'p_complet': full,
            'p_station': station,
            'p_justificatifs': tickets,
            'p_saisi_le': enteredAt.toUtc().toIso8601String(),
          }));

  /// Storage of the receipts (same as the web application).
  static const ticketBucket = 'justificatifs';

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      // Business refusals (P0001 / PT403) carry a French message for the user.
      throw MissionsGatewayException(e.message);
    } on http.ClientException {
      throw const MissionsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);
    } on SocketException {
      throw const MissionsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);
    } on TimeoutException {
      throw const MissionsGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);
    } on AuthException {
      throw const MissionsGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
