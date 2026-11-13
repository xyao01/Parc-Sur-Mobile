import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vehicle_gateway.dart';

class SupabaseVehicleGateway implements VehicleGateway {
  SupabaseVehicleGateway(this._client);

  final SupabaseClient _client;

  static const _offline = VehicleGatewayException('Connexion impossible. Vérifiez votre réseau et réessayez.', network: true);

  @override
  Future<List<Map<String, dynamic>>> myVehicles() => _guard(() async {
        final result = await _client.rpc('mon_vehicule');
        return [for (final r in (result as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
      });

  @override
  Future<Map<String, dynamic>> recordMonthly({
    required String id,
    required String vehicleId,
    required int odometerKm,
    required DateTime date,
  }) =>
      _guard(() async {
        // p_id_client selects the idempotent version of saisir_releve_mensuel.
        final r = await _client.rpc('saisir_releve_mensuel', params: {
          'p_vehicule': vehicleId,
          'p_kilometrage': odometerKm,
          'p_date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'p_id_client': id,
        });
        return r is Map ? Map<String, dynamic>.from(r) : const {};
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw VehicleGatewayException(e.message);
    } on http.ClientException {
      throw _offline;
    } on SocketException {
      throw _offline;
    } on TimeoutException {
      throw _offline;
    } on AuthException {
      throw const VehicleGatewayException('Votre session a expiré. Reconnectez-vous.');
    }
  }
}
