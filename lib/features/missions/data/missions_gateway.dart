/// Port over the driver mission calls, so screens can be tested without Supabase.
abstract interface class MissionsGateway {
  /// `mes_missions_chauffeur()`: missions of the signed-in driver.
  Future<List<Map<String, dynamic>>> myMissions();

  /// `enregistrer_controle(...)`: departure / return check. Idempotent on [id].
  Future<void> recordControl({
    required String id,
    required String missionId,
    required String type,
    required int odometerKm,
    required String fuel,
    required Map<String, String> points,
    required DateTime enteredAt,
  });
}

/// Refusal with a message meant for the user (the database raises French messages).
class MissionsGatewayException implements Exception {
  const MissionsGatewayException(this.message, {this.network = false});

  final String message;
  final bool network;

  @override
  String toString() => 'MissionsGatewayException($message)';
}
