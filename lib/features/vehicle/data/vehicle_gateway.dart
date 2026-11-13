/// Port over the « mon véhicule » calls of an agent with an assigned vehicle (l2-km-02).
abstract interface class VehicleGateway {
  /// `mon_vehicule()`: vehicles assigned to the signed-in agent, last readings, current month status.
  Future<List<Map<String, dynamic>>> myVehicles();

  /// `saisir_releve_mensuel(p_vehicule, p_kilometrage, p_date, p_id_client)`; idempotent on [id].
  /// Returns `{aVerifier, motif}`.
  Future<Map<String, dynamic>> recordMonthly({
    required String id,
    required String vehicleId,
    required int odometerKm,
    required DateTime date,
  });
}

class VehicleGatewayException implements Exception {
  const VehicleGatewayException(this.message, {this.network = false});

  final String message;
  final bool network;

  @override
  String toString() => 'VehicleGatewayException($message)';
}
